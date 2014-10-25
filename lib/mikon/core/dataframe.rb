require 'securerandom'
require 'json'

module Mikon
  class DataFrame
    include Enumerable

    def initialize(source, options={})
      options = {
        name: SecureRandom.uuid(),
        index: nil,
        columns: nil
      }.merge(options)

      case
      when source.is_a?(Array)
        case
        when source.all? {|el| el.is_a?(Mikon::Series)}
          raise "NotImplementedError"

        when source.all? {|el| el.is_a?(Mikon::Row)}
          @labels = source.first.labels
          @data = source.map{|row| row.to_hash.values}.transpose.map do |arr|
            Mikon::DArray.new(arr)
          end

        when source.all? {|el| el.is_a?(Hash)}
          @labels = source.first.keys
          @data = source.map{|hash| hash.values}.transpose.map do |arr|
            Mikon::DArray.new(arr)
          end

        when source.all? {|el| el.is_a?(Array)}
          raise "options[:index] should be set." if options[:index].nil?
          @labels = options[:index]
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

      @index = options[:index]
      @name = options[:name]

      _check_is_valid
    end

    def _check_is_valid
      # All array should should have the same length
      length = @data.map{|darr| darr.length}.max
      @data.each{|darr| darr.expand(length) if darr.length < length}

      # DataFrame should have index object
      @index = (0..(length-1)).to_a if @index.nil?
      raise "index should have the same length as arrays" if @index.length != length

      # Labels should be an instance of Symbol
      if @labels.any?{|label| !label.is_a?(Symbol)}
        @labels = @labels.map{|label| label.to_sym}
      end
    end

    def length
      @data.first.length
    end

    def from_csv(url, options={})
      options = {
        :col_sep => ',',
        :headers => true,
        :converters => :numeric,
        :header_converters => :symbol
      }.merge(options)

      self.new([], options)
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

    def each(&block)
      raise "NotImplementedError"
    end

    def to_json
      rows = []
      self.each_row do |row|
        rows.push(row.to_hash)
      end
      rows.to_json
    end

    def to_html
      html = "<html><table><tr><td></td>"
      html += @labels.map{|label| "<th>" + label.to_s +  "</th>"}.join
      html += "</tr>"
      rows = []
      self.each_row{|row| rows.push(["<tr>"] + row.arr.map{|el| "<td>" + el.to_s + "</td>"} + ["</tr>"])}
      html += rows.map.with_index{|arr, i| arr.insert(1, "<th>" + @index[i].to_s + "</th>").join}.join
      html += "</table>"
    end

    def to_s
      self.to_html
    end

    def select(&block)
      rows = []
      self.each_row do |row|
        rows.push(row) if row.instance_eval(&block)
      end
      Mikon::DataFrame.new(rows, index: @index)
    end

    def row(index)
      pos = @index.index(index)
      arr = @data.map{|column| column[pos]}
      Mikon::Row.new(@labels, arr)
    end

    def each_row(&block)
      @index.each.with_index do |el, i|
        row_arr = @data.map{|darr| darr[i]}
        row = Mikon::Row.new(@labels, row_arr)
        block.call(row)
      end
    end

    alias_method :filter, :select
    attr_reader :name, :index, :labels
  end

  # Row class for internal use
  class Row
    def initialize(labels, arr)
      @labels = labels
      @arr = arr
    end

    def [](name)
      pos = @labels.index(name)
      pos.nil? ? nil : @arr[pos]
    end

    # @example
    #   row = Row.new([:a, :b, :c], [1, 2, 3])
    #   puts row.instance_eval { a * b * c} #-> 7
    def method_missing(name, *args)
      super unless args.length == 0
      pos = @labels.index(name)
      raise "InvalidBlockError" if pos.nil?
      @arr[pos]
    end

    def to_hash
      @labels.each.with_index.reduce({}) do |memo, (label, i)|
        memo[label] = @arr[i]
        memo
      end
    end

    attr_reader :labels, :arr
  end
end
