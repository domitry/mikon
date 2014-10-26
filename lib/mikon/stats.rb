require 'forwardable'

module Mikon
  module Stats
    extend Forwardable
    def_delegators :@data, :size, :max, :min, :push
    alias_method :n, :size
    # alias_method :standard_deviation_sample, :sd
    # alias_method :standard_deviation_sample, :sds
    # alias_method :standard_deviation_population, :sdp
    # alias_method :standard_error, :se

    def median
      self.percentil(50)
    end

    def mode
    end

    def n_valid
    end

    def percentil(p)
    end

    def product
      @data.inject(1){|memo, val| memo*val}
    end

    def proportion
    end

    def proportion_confidence_interval_t
      raise "NotImplementedError"
    end

    def proportion_confidence_interval_z
      raise "NotImplementedError"
    end

    def proportions
    end

    def range
      max - min
    end

    def mean
      @data.mean.first
    end
  end
end
