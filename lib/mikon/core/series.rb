require 'forwardable'

module Mikon
  class Series
    include Enumerable
    extend Forwardable
    def_delegators :@data, :max, :min
    def_delegators :@data, *(Mikon::Stats.instance_methods)
    attr_reader :index, :name

    def initialize(name, source, options={})
      options = {
        index: nil
      }.merge(options)

      case
      when source.is_a?(Array) || source.is_a?(NMatrix)
        @data = Mikon::DArray.new(source)
      when source.is_a?(Mikon::DArray)
        @data = source
      else
        raise "Non-acceptable Arguments Error"
      end

      @index = options[:index]
      @name = name

      _check_if_valid
    end

    def _check_if_valid
      @index = (0..(length-1)).to_a if @index.nil?
      raise "index should have the same length as arrays" if @index.length != @data.length
    end

    def length
      @data.length
    end

    def each(&block)
      @data.each(&block)
    end

    def [](arg)
      pos = @index.index(arg)
      raise "There is no index named" + arg.to_s if pos.nil?
      @data[pos]
    end

    def to_html(threshold=5)
      html = "<table><tr><th></th><th>" + self.name.to_s + "</th></tr>"
      @index.each.with_index do |index, pos|
        next if pos > threshold && pos != self.length-1
        html += "<tr><th>" + index.to_s + "</th><td>" + @data[pos].to_s + "</td></tr>"
        html += "<tr><th>...</th><td>...</td></tr>" if pos == threshold
      end
      html + "</table>"
    end

    def to_s(threshold=5)
      arr = []
      @index.each.with_index do |index, pos|
        next nil if pos > threshold && pos != self.length-1
        arr.push({"" => index, @name => @data[pos]})
        arr.push({"" => "...", @name => "..."}) if pos == threshold
      end
      Formatador.display_table(arr.select{|el| !(el.nil?)})
    end

    def to_json(*args)
      @data.to_json
    end

    def name(new_name=nil)
      if new_name.nil?
        @name
      else
        @name = new_name
        self
      end
    end

    def to_a
      @data.to_a
    end

    def to_darr
      @data
    end

    def *(arg)
      if arg.is_a?(Numeric)
        Series.new(self.name, @data*arg, index: self.index)
      else
        raise ArgumentError
      end
    end

    def /(arg)
      if arg.is_a?(Numeric)
        Series.new(self.name, @data/arg, index: self.index)
      else
        raise ArgumentError
      end
    end

    def %(arg)
      if arg.is_a?(Numeric)
        Series.new(self.name, @data%arg, index: self.index)
      else
        raise ArgumentError
      end
    end

    def -(arg)
      if arg.is_a?(Mikon::Series) && arg.length == self.length
        Series.new(self.name, arg.coerce(@data).inject(:-), index: self.index)
      else
        raise ArgumentError
      end
    end

    def +(arg)
      if arg.is_a?(Mikon::Series) && arg.length == self.length
        Series.new(self.name, arg.coerce(@data).inject(:+), index: self.index)
      else
        raise ArgumentError
      end
    end

    def coerce(other)
      if other.is_a?(Mikon::DArray)
        return other, @data
      elsif other.is_a?(Numeric)
        return self, other
      else
        raise ArgumentError
      end
    end

    private :_check_if_valid
  end
end
