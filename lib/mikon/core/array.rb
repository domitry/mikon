module Mikon
  class DArray
    include Enumerable

    def initialize(source, options={})
      case
      when source.is_a? Array
        if source.all? {|el| el.is_a? Numeric || el.nil?}
          @data = NMatrix.new([source.length], source, options)
        else
          @data = NMatrix.new([source.length], source, options.merge{:dtype => :object})
        end

      when source.is_a? NMatrix
        unless source.shape.length == 1 && source.shape.first.is_a? Numeric
          raise "Matrix shape is not valid"
        end
        @data = source

      else raise "Non-acceptable Arguments Error"
      end

      @dtype = @data.dtype
    end

    def each(block)
      @data.each(block)
    end

    def expand(length)
      raise "The argument 'length' should be greater than length of now." if length < self.length
      data = NMatrix.new([expand], @data.to_a)
      @data = data.map.with_index{|val, i| i < self.length ? val : 0}
    end

    def length
      @data.shape.first
    end

    def [](pos)
      @data[pos]
    end

    attr_reader :dtype, :data
  end
end
