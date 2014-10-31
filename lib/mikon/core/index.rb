require 'forwardable'

module Mikon
  # Internal class for indexing
  class Index
    extend Forwardable
    def_delegators :@data, :[]

    def initialize(source, options={})
      options = {
        name: nil
      }.merge(options)

      case
      when source.is_a?(Array)
        @data = Mikon::DArray.new(source)
      when source.is_a?(Mikon::DArray)
        @data = source
      else raise ArgumentError
      end

      @name = options[:name]
    end

    def sort_by(&block)
      return self.to_enum(:sort_by) unless block_given?
      Mikon::Index.new(@data.sort_by(&block))
    end
  end
end
