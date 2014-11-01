require 'spec_helper'

describe Mikon::DataFrame do
  before(:each) do
    @df = Mikon::DataFrame.new([{a: 1, b: 5}, {a: 2, b: 2}, {a: 3, b: 4}])
  end

  context ".new" do
    {
      hash_in_array: [{a: 1, b: 2}, {a: 2, b: 3}, {a: 3, b: 4}],
      darray_in_array: [[1, 2, 3], [2, 3, 4]].map{|column| Mikon::DArray.new(column)},
      row_in_array: [1, 2, 3].map{|val| Mikon::Row.new([:a, :b], [val, val+1], [0, 1])},
      array_in_array: [[1, 2, 3], [2, 3, 4]],
      array_in_hash: {a: [1,2,3], b: [2,3,4]}
    }.each do |name, input|
      it "should accept " + name.to_s + " input" do
        df = Mikon::DataFrame.new(input, labels: [:a, :b])
        expect(df[:a].to_a).to eq([1, 2, 3])
      end

      it "should be able to be specified its indices" do
        df = Mikon::DataFrame.new(input, index: [:a, :b, :c])
        expect(df.index).to eq([:a, :b, :c])
      end

      it "should be able to be specified its labels" do
        df = Mikon::DataFrame.new(input, labels: [:foo, :bar])
        expect(df.labels).to eq([:foo, :bar])
      end

      it "should assign unique id to each dataframe" do
        df1, df2 = [0, 1].map{Mikon::DataFrame.new(input, labels: [:a, :b])}
        expect(df1.name == df2.name).to eq(false)
      end
    end
  end

  context ".from_csv" do
    it "should accept csv file" do
      path = File.expand_path("../../data/test.csv", __FILE__)
      df = Mikon::DataFrame.from_csv(path)
      expect(df[:a].to_a).to eq([1, 3])
    end

    it "should accept tsv file" do
      path = File.expand_path("../../data/test.tsv", __FILE__)
      df = Mikon::DataFrame.from_csv(path, col_sep: "\t")
      expect(df[:a].to_a).to eq([1, 3])
    end

    it "should accept no-header csv" do
      path = File.expand_path("../../data/no_header.csv", __FILE__)
      df = Mikon::DataFrame.from_csv(path, headers: [:a, :b])
      expect(df[:a].to_a).to eq([1, 3])
    end
  end

  context "#head" do
    it "should be return a partial dataframe" do
      expect(@df.head(2).class).to eq(Mikon::DataFrame)
      expect(@df.head(2)[:a].to_a).to eq([1, 2])
    end

    it "should keep index number" do
      expect(@df.head(2).index).to eq([0, 1])
    end
  end

  context "#tail" do
    it "should be return a partial dataframe" do
      expect(@df.tail(2).class).to eq(Mikon::DataFrame)
      expect(@df.tail(2)[:a].to_a).to eq([2, 3])
    end

    it "should keep index number" do
      expect(@df.tail(2).index).to eq([1, 2])
    end
  end

  context "#length" do
    it "should return the length of each column" do
      @df.labels.each do |label|
        expect(@df.length).to eq(@df[label].length)
      end
    end
  end

  context "#[]" do
    it "should return an instance of Mikon::Series if Symbol is passed" do
      expect(@df[:a].to_a).to eq([1,2,3])
    end

    it "should return partial dataframe if Array of Numerics is passed" do
      expect(@df[0..1][:a].to_a).to eq([1,2])
    end
  end

  context "#to_html" do
    it "should return a valid html" do
      html = @df.to_html
      expect(html.count("<")).to eq(html.count(">"))
    end
  end

  context "#to_json" do
    it "should return a valid json" do
      json = @df.to_json
      expect(json.count("{")).to eq(json.count("}"))
      expect(json.count("[")).to eq(json.count("]"))
    end
  end

  context "#select" do
    it "should return Enumurator if block is not passed" do
      expect(@df.select.class).to eq(Enumerator)
    end

    it "should return partial dataframe" do
      df = @df.select{ a < 2}
      expect(df.class).to eq(Mikon::DataFrame)
      expect(df.length).to eq(1)
      expect(df[:a].to_a).to eq([1])
    end
  end

  context "#map" do
    it "should return Enumurator if block is not passed" do
      expect(@df.map.class).to eq(Enumerator)
    end

    it "should return an instance of Mikon::Series" do
      series = @df.map{a*2}.name(:c)
      expect(series.class).to eq(Mikon::Series)
      expect(series.to_a).to eq([2, 4, 6])
      expect(series.name).to eq(:c)
    end
  end

  context "#all?" do
    it "should accept Mikon::Row DSL" do
      expect(@df.all?{a<=3 && b<0}).to eq(false)
    end
  end

  context "#any?" do
    it "should accept Mikon::Row DSL" do
      expect(@df.any?{b<3}).to eq(true)
    end
  end

  context "#sort_by" do
    it "should accept Mikon::Row DSL" do
      expect(@df.sort_by{b}.index).to eq([1, 2, 0])
    end
  end

  context "#sort" do
    it "should decide which column to sort with by the first argument" do
      # b: [5, 2, 4]
      expect(@df.sort(:b).index).to eq([1, 2, 0])
    end
    it "shoudl decide if do ascending sort by the second argument" do
      expect(@df.sort(:b, false).index).to eq([1, 2, 0].reverse)
    end
  end

  context "#insert_column" do
    it "should use Mikon::Row DSL when block is passed" do
      @df.insert_column(:c){a*2}
      expect(@df[:c].to_a).to eq([2, 4, 6])
    end

    it "should accept Array as a second argument" do
      @df.insert_column(:c, [2, 4, 6])
      expect(@df[:c].to_a).to eq([2, 4, 6])
    end

    it "should accept Series as a second argument" do
      @df.insert_column((@df[:a]*2).name(:c))
      expect(@df[:c].to_a).to eq([2, 4, 6])
    end
  end

  context "row" do
    it "should return row whose index is specified one" do
      row = @df.row(1)
      expect(row.class).to eq(Mikon::Row)
      expect(row.index).to eq(1)
      expect(row.labels).to eq([:a, :b])
    end
  end

  context "#each_row" do
    it "should be iterate row as Mikon::Row" do
      check = []
      @df.each_row{|row| check.push(row.is_a?(Mikon::Row))}
      expect(check.all?{|val| val}).to eq(true)
    end
  end
end
