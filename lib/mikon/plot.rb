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
        plot.add(:histogram, @data.to_a)
      when :line
        plot.add(:line, @index, @data.to_a)
      end

      plot
    end
  end

  class DataFrame
    def plot(args={})
      args = {
        :type => :line,
        :x => nil,
        :y => nil,
        :fill_by => nil,
        :color => nil
      }.merge(args)

      plot = Nyaplot::Plot.new
      plot.x_label("")
      plot.y_label("")

      unless args[:color].nil?
        colors = Nyaplot::Colors.send(args[:color]).to_a
      else
        colors = Nyaplot::Colors.qual.to_a
      end

      case args[:type]
      when :line
        @data.each.with_index do |darr, i|
          line = plot.add(:line, @index, darr.to_a)
          line.color(colors.pop)
          line.title(@labels[i])
        end
        plot.legend(true)

      when :box
        plot.add_with_df(self, :box, *@labels)

      when :scatter
        sc = plot.add_with_df(self, :scatter, args[:x], args[:y])
        sc.color(colors)
        sc.fill_by(args[:fill_by]) unless args[:fill_by].nil?
        plot.x_label(args[:x])
        plot.y_label(args[:y])
      end

      plot
    end
  end
end
