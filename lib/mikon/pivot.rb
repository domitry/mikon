module Mikon
  class DataFrame
    # Experimental Implementation.
    # DO NOT USE THIS METHOD
    def pivot(args={})
      args = {
        column: nil,
        row: nil,
        value: nil,
        fill_value: Float::NAN
      }.merge(args)

      raise ArgumentError unless [:column, :row, :value].all?{|sym| args[sym].is_a?(Symbol)}

      column = self[args[:column]].factors
      index = self[args[:row]].factors

      source = column.reduce({}) do |memo, label|
        arr = []
        df = self.select{|row| row[args[:column]] == label}
        index.each do |i|
          unless df.any?{|row| row[args[:row]] == i}
            arr.push(args[:fill_value])
          else
            column = df.select{|row| row[args[:row]] == i}[args[:value]]
            arr.push(column.to_a[0])
          end
        end
        memo[label] = arr
        memo
      end

      Mikon::DataFrame.new(source, index: index)
    end
  end
end
