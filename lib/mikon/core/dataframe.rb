require 'securerandom'
require 'json'
require 'csv'

module Mikon

  # The main data structure in Mikon gem.
  # DataFrame consists of labels(column name), index(row name), and labels.
  class DataFrame

    def initialize(source, options={})
      options = {
        name: SecureRandom.uuid(),
        index: nil,
        labels: nil
      }.merge(options)

      case
      when source.is_a?(Array)
        case
        when source.all? {|el| el.is_a?(Mikon::Series)}
          raise "NotImplementedError"

        when source.all? {|el| el.is_a?(Mikon::DArray)}
          @data = source

        when source.all? {|el| el.is_a?(Mikon::Row)}
          @labels = source.first.labels
          @index = source.map{|row| row.index}
          @data = source.map{|row| row.to_hash.values}.transpose.map do |arr|
            Mikon::DArray.new(arr)
          end

        when source.all? {|el| el.is_a?(Hash)}
          @labels = source.first.keys
          @data = source.map{|hash| hash.values}.transpose.map do |arr|
            Mikon::DArray.new(arr)
          end

        when source.all? {|el| el.is_a?(Array)}
          @data = source.map do |arr|
            Mikon::DArray.new(arr)
          end

        else raise "Non-acceptable Arguments Error"
        end

      when source.is_a?(Hash)
        case
        when source.values.all? {|val| val.is_a?(Array)}
          @labels = source.keys
          @data = source.values.map do |arr|
            Mikon::DArray.new(arr)
          end
        when source.all? {|arr| arr[1].is_a?(Series)}
        else raise "Non-acceptable Arguments Error"
        end

      else raise "Non-acceptable Arguments Error"
      end

      @labels = options[:labels] unless options[:labels].nil?
      @name = options[:name]

      unless (index = options[:index]).nil?
        if index.is_a?(Symbol)
          raise "labels should be set" if @labels.nil?
          pos = @labels.index(index)
          raise "Thre is no column named" + index.to_s if pos.nil?
          name = @labels.delete(index)
          @index = @data.delete(@data[pos])
        elsif index.is_a?(Array)
          @index = index
        else
          raise "Invalid index type"
        end
      end

      _check_if_valid
    end

    def _check_if_valid
      # All array should should have the same length
      length = @data.map{|darr| darr.length}.max
      @data.each{|darr| darr.expand(length) if darr.length < length}

      # DataFrame should have index object
      @index = (0..(length-1)).to_a if @index.nil?
      raise "index should have the same length as arrays" if @index.length != length

      # Labels should be an instance of Symbol
      if @labels.nil?
        @labels = @data.map.with_index{|darr, i| i.to_s.to_sym}
      elsif @labels.any?{|label| !label.is_a?(Symbol)}
        @labels = @labels.map{|label| label.to_sym}
      end
    end

    # return the length of columns
    def length
      @data.first.length
    end

    # Create Mikon::DataFrame from a csv/tsv file
    # @param [String] path path to csv
    # @param options
    #   :col_sep [String] string to separate by
    #   :headers [Array] headers
    #
    def self.from_csv(path, options={})
      csv_options = {
        :col_sep => ',',
        :headers => true,
        :converters => :numeric,
        :header_converters => :symbol,
      }

      options = csv_options.merge(options)
      raise ArgumentError, "options[:hearders] should be set" if options[:headers] == false

      csv = CSV.readlines(path, "r", options)
      yield csv if block_given?

      hash = {}
      csv.by_col.each {|label, arr| hash[label] = arr}
      csv_options.keys.each{|key| options.delete(key)}

      self.new(hash, options)
    end

    # Accessor for column and rows
    # @example
    #   df = DataFrame.new({a: [1, 2, 3], b: [2, 3, 4]})
    #   df[0..1].to_json #-> {a: [1, 2], b: [2, 3]}
    #   df[:a] #-> <Mikon::Series>
    def [](arg)
      case
      when arg.is_a?(Range)
        index = @index.select{|i| arg.include?(i)}
        Mikon::DataFrame.new(index.map{|i| self.row(i)}, {index: index})

      when arg.is_a?(Symbol)
        self.column(arg)
      end
    end

    def column(label)
      pos = @labels.index(label)
      raise "There is no column named " + label if pos.nil?
      Mikon::Series.new(label, @data[pos])
    end

    def head(num)
      self[0..(num-1)]
    end

    def tail(num)
      last = self.length-1
      self[(last-num+1)..last]
    end

    def to_json(*args)
      rows = []
      self.each_row do |row|
        rows.push(row.to_hash)
      end
      rows.to_json
    end

    def to_html(threshold=50)
      html = "<html><table><tr><td></td>"
      html += @labels.map{|label| "<th>" + label.to_s +  "</th>"}.join
      html += "</tr>"
      self.each_row.with_index do |row, pos|
        next if pos > threshold && pos != self.length-1
        html += "<tr><th>" + @index[pos].to_s + "</th>"
        html += @labels.map{|label| "<td>" + row[label].to_s + "</td>"}.join
        html += "</tr>"
        html += "<tr><th>...</th>" + "<td>...</td>"*@labels.length + "</tr>" if pos == threshold
      end
      html += "</table>"
    end

    def select(&block)
      rows = []
      i = 0
      self.each_row do |row|
        if row.instance_eval(&block)
          rows.push(row)
        end
      end
      Mikon::DataFrame.new(rows)
    end

    alias_method :filter, :select

    def each(&block)
      return self.to_enum(:each) unless block_given?
      self.each_row do |row|
        row.instance_eval(&block)
      end
      self
    end

    def map(&block)
      return self.to_enum(:map) unless block_given?
      arr = []
      self.each_row do |row|
        arr.push(row.instance_eval(&block))
      end
      Mikon::Series.new(:new_series, arr, index: @index)
    end

    alias_method :collect, :map

    def all?(&block)
      self.each_row {|row| return false unless row.instance_eval(&block)}
      true
    end

    def any?(&block)
      self.each_row {|row| return true if row.instance_eval(&block)}
      false
    end

    def sort_by(ascending=true, &block)
      return self.to_enum(:sort_by) unless block_given?
      order = self.map(&block).to_darr.sorted_indices
      order.reverse! unless ascending
      data = @data.map{|darr| darr.sort_by.with_index{|val, i| order.index(i)}}
      index = @index.sort_by.with_index{|val, i| order[i]}
      Mikon::DataFrame.new(data, {index: index, labels: @labels})
    end

    def sort(label, ascending=true)
      i = @labels.index(label)
      raise "No column named" + label.to_s if i.nil?
      order = @data[i].sorted_indices
      order.reverse! unless ascending
      self.sort_by.with_index{|val, i| order.index(i)}
    end

    # @example
    #   df = Mikon::DataFrame.new({a: [1,2,3], b: [2,3,4]})
    #   df.insert_column(:c){a + b}.to_json #-> {a: [1,2,3], b: [2,3,4], c: [3, 5, 7]}
    #   df.insert_column(:d, [1, 2, 3]).to_json #-> {a: [1,2,3], b: [2,3,4], c: [3, 5, 7], d: [1, 2, 3]}
    #
    def insert_column(name, arr=[], &block)
      rows = []
      if block_given?
        self.each_row do |row|
          val = row.instance_eval(&block)
          row[name] = val
          rows.push(row)
        end
        @data = rows.map{|row| row.to_hash.values}.transpose.map do |arr|
          Mikon::DArray.new(arr)
        end
        @labels = rows.first.labels
      else
        @data.push(Mikon::DArray.new(arr))
        @labels.push(name)
      end
      _check_if_valid
      return self
    end

    def row(index)
      pos = @index.index(index)
      arr = @data.map{|column| column[pos]}
      Mikon::Row.new(@labels, arr, index)
    end

    def each_row(&block)
      return self.to_enum(:each_row) unless block_given?
      @index.each.with_index do |el, i|
        row_arr = @data.map{|darr| darr[i]}
        row = Mikon::Row.new(@labels, row_arr, @index[i])
        block.call(row)
      end
    end

    attr_reader :name, :index, :labels
  end

  # Row class for internal use
  class Row
    def initialize(labels, arr, index)
      @labels = labels
      @arr = arr
      @index = index
    end

    def [](name)p
      pos = @labels.index(name)
      pos.nil? ? nil : @arr[pos]
    end

    def []=(name, val)
      pos = @labels.index(name)
      if pos.nil?
        @labels.push(name)
        @arr.push(val)
      else
        @arr[pos] = val
      end
    end

    # @example
    #   row = Row.new([:a, :b, :c], [1, 2, 3], :example_row)
    #   puts row.instance_eval { a * b * c} #-> 7
    def method_missing(name, *args)
      super unless args.length == 0
      pos = @labels.index(name)
      pos.nil? ? super : @arr[pos]
    end

    def to_hash
      @labels.each.with_index.reduce({}) do |memo, (label, i)|
        memo[label] = @arr[i]
        memo
      end
    end

    attr_reader :labels, :arr, :index
  end
end
