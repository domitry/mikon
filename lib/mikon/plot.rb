require 'nyaplot'

module Mikon
  class Series
    def plot(args={})
      args = {
        :type => :histogram
      }.merge(args)

      plot = Nyaplot::Plot.new

      case args[:type]
      when :histogram
        arr = @data.to_a
        plot.add(args[:type], arr)
      end

      plot
    end
  end
end
