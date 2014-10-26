module Mikon
  class DArray
    include Enumerable, Mikon::Stats
    attr_reader :dtype, :data

    # @param [NMatrix|Array] source
    # @param [Hash] options
    def initialize(source, options={})
      case
      when source.is_a?(Array)
        if source.all? {|el| el.is_a?(Numeric)}
          @data = NMatrix.new([source.length], source, options)
        else
          #
          # NMatrix instance whose dtype is :object frequently causes Segmentation Fault
          # @example
          #   df = DataFrame.new({a: ["a", "b"], b: [1, 2]})
          #   df[:a].to_html #-> Segmentation Fault
          #

          # @data = NMatrix.new([source.length], source, options.merge({:dtype => :object}))
          extend UseArray
          @data = Mikon::ArrayWrapper.new(source)
        end

      when source.is_a?(NMatrix)
        unless source.shape.length == 1 && source.shape.first.is_a?(Numeric)
          raise "Matrix shape is not valid"
        end
        @data = source
      else
        raise "Non-acceptable Argument Error"
      end
      @dtype = @data.dtype
    end

    def each(&block)
      @data.each(&block)
    end

    def reduce(init, &block)
      @data.inject_rank(0, init, &block).first
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

    [:+, :-].each do |op|
      define_method(op) do |arg|
        if arg.is_a?(DArray)
          DArray.new(arg.coerce(@data).inject(op))
        else
          super
        end
      end
    end

    [:*, :/, :%].each do |op|
      define_method(op) do |arg|
        if arg.is_a?(Numeric)
          DArray.new(@data.send(op, arg))
        else
          super
        end
      end
    end

    def coerce(other)
      if [NMatrix, Array].any?{|cls| other.is_a?(cls) && @data.is_a?(cls)}
        return other, @data
      else
        super
      end
    end

    def to_a
      @data.to_a
    end
  end

  class ArrayWrapper < Array
    def dtype
      :object
    end
  end

  module UseArray
    def expand(length)
      @data = @data + Array(length - @data.length, 0)
    end

    def length
      @data.length
    end

    def reduce(init, &block)
      @data.reduce(int, &block)
    end
  end
end
