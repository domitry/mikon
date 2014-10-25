module Mikon
  include Enumerable

  class Series
    def initialize(name, source, options={})
      options = {
        index: nil
      }

      case
      when source.is_a? Array || source.is_a? NMatrix
        @data = Mikon::DArray.new(source)
      when source.is_a? Mikon::DArray
        @data = source
      else raise "Non-acceptable Arguments Error"
      end

      @index = options[:index]
      @name = name

      _check_is_valid
    end

    private
    def _check_is_valid
      @index = (0..(length-1)).to_a if @index.nil?
      raise "index should have the same length as arrays" if @index.length != @data.length
    end

    def each(block)
      @data.each(block)
    end

    def [](arg)
      pos = @arg.index(arg)
      raise "There is no index named" + arg.to_s if pos.nil?
      @data[pos]
    end
  end
end
