require 'forwardable'

# Implementation of statistical functions. Make DArray compatible with Statsample::Vector.
#
module Mikon
  module Stats
    extend Forwardable
    def_delegators :@data, :size, :max, :min, :push

    def average_deviation_population(m=nil)
      m ||= self.mean
      (self.reduce(0){|memo, val| val + (val - m).abs})/self.length
    end

    def coefficient_of_variation
      self.standard_deviation_sample/self.mean
    end

    def count(x=false)
      if block_given?
        self.reduce(0){|memo, val| memo += 1 if yield val; memo}
      else
        val = self.frequencies[x]
        val.nil? ? 0 : val
      end
    end

    def each(&block)
      return self.to_enum(:each) unless block_given?
      @data.each_along_dim(0, &block)
    end

    def each_index(&block)
      self.each.with_index(&block)
    end

    # uniq
    def factors
      index = @data.sorted_indices
      index.reduce([]){|memo, val| memo.push(@data[val]) if memo.last != val}
    end

    def frequencies
      index = @data.sorted_indices
      index.reduce({}){|memo, val| memo[@data[val]] ||= 0; memo[@data[val]] += 1; memo}
    end

    def has_missing_data?
      false
    end

    def is_valid?
      true
    end

    def kurtosis(m=nil)
      m ||= self.mean
      fo=self.reduce(0){|a, x| a+((x-m)**4)}
      fo.quo(self.length*sd(m)**4)-3
    end

    # alias_method :label, :labeling
    # labeling(x) would be not implemented

    def mean
      @data.mean.first
    end

    def median
      self.percentil(50)
    end

    def median_absolute_deviation
      m = self.median
      self.recode{|val| (val-m).abls}.median
    end

    def mode
      self.frequencies.max
    end

    def ==(other)
      @data==other
    end

    def n_valid
      self.length
    end

    def percentil(percent)
      index = @data.sorted_indices
      pos = (self.length * percent)/100
      if pos.to_i == pos
        @data[index[pos.to_i]]
      else
        pos = (pos-0.5).to_i
        (@data[index[pos]] + @data[index[pos+1]])/2
      end
    end

    def product
      @data.inject(1){|memo, val| memo*val}
    end

    def proportion(val=1)
      self.frequencies[val]/self.n_valid
    end

    def proportion_confidence_interval_t
      raise "NotImplementedError"
    end

    def proportion_confidence_interval_z
      raise "NotImplementedError"
    end

    def proportions
      len = self.n_valid
      self.frequencies.reduce({}){|memo, arr| memo[arr[0]] = arr[1]/len}
    end

    def push(val)
      self.expand(self.length+1)
      self[self.length-1] = recode
    end

    def range
      max - min
    end

    # ?
    def ranked
      sum = 0
      r = self.frequencies.sort.reduce({}) do |memo, val|
        memo[val[0]] = ((sum+1) + (sum+val[1]))/2
        sum += val[1]
        memo
      end
      Mikon::DArray.new(self.reduce{|val| r[val]})
    end

    def recode(&block)
      Mikon::DArray.new(@data.map(&block))
    end

    def recode!(&block)
      @data.map!(&block)
    end

    # report_building(b) would not be implemented
    # sample_with_replacement
    # sample_without_replacement

    # set_valid_data

    def skew(m=nil)
      m ||= self.mean
      th = self.reduce(0){|memo, val| memo + ((val - m)**3)}
      th/((self.length)*self.sd(m)**3)
    end

    # split_by_separator_freq
    # splitted

    def standard_deviation_population(m=nil)
      m ||= self.mean
      Math.sqrt(self.variance_population(m))
    end

    def standard_deviation_sample(m=nil)
      if !m.nil?
        Math.sqrt(variance_sample(m))
      else
        @data.std.first
      end
    end

    def standard_error
      self.standard_deviation_sample/(Math.sqrt(self.length))
    end

    def sum_of_squared_deviation
      self.reduce(0){|memo, val| val**2 + memo}
    end

    def sum_of_squares(m=nil)
      m ||= self.mean
      self.reduce(0){|memo, val| memo + (val-m)**2}
    end

    def sum
      @data.sum.first
    end

    # today_values
    # type=

    # def variance_population
    # def variance_proportion

    def variance_sample(m=nil)
      m ||= self.mean
      self.sum_of_squares(m)/(self.length-1)
    end

    # def variance_total
    # def vector_centered
    # def vector_labeled
    # def vector_percentil

    def vector_standarized
      raise "NotImplementedError"
    end

    alias_method :n, :size
    alias_method :sd, :standard_deviation_sample
    alias_method :sds, :standard_deviation_sample
    alias_method :sdp, :standard_deviation_population
    alias_method :se, :standard_error
    alias_method :adp, :average_deviation_population
    alias_method :mad, :median_absolute_deviation
    alias_method :ss, :sum_of_squares
    alias_method :flawed?, :has_missing_data?
    alias_method :standarized, :vector_standarized
    alias_method :variance, :variance_sample
  end
end
