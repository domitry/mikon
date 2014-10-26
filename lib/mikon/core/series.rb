module Mikon
  class Series
    include Enumerable

    def initialize(name, source, options={})
      options = {
        index: nil
      }

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

    def each(block)
      @data.each(block)
    end

    def [](arg)
      pos = @arg.index(arg)
      raise "There is no index named" + arg.to_s if pos.nil?
      @data[pos]
    end

    def to_html
      html = "<table><tr><th></th><th>" + self.name.to_s + "</th></tr>"
      html += @index.map.with_index do |index, pos|
        "<tr><th>" + index.to_s + "</th><td>" + @data[pos].to_s + "</td></tr>"
      end.join
      html + "</table>"
    end

    attr_reader :name
    private :_check_if_valid
  end
end
