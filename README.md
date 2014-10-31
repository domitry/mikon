# ☗ Mikon
Mikon is a flexible data structure for Ruby language, inspired by data.frame of R and Pandas of Python.

Features:
* Fast data manipulation with [NMatrix](https://github.com/SciRuby/nmatrix)
* Compatibility with [Statsample::Vector](https://github.com/clbustos/statsample) 
* Advanced plotting with [Nyaplot](https://github.com/domitry/nyaplot)

## Dependencies
* CRuby >= 2.0.0-p451
* NMatrix  >= v0.1.0.rc5

### Optional Dependencies
* Nyaplot: for plotting
* Statsample: for statistical function

## Installation

    $ gem install mikon

## Usage
### Initializing DataFrame

```ruby
require 'mikon'
df2 = Mikon::DataFrame.new([{a: 1, b: 2}, {a: 2, b: 3}, {a: 3, b: 4}])
```
![init0](https://dl.dropboxusercontent.com/u/47978121/mikon/init0.png)

```ruby
Mikon::DataFrame.new({a: [1,2,3,4], b: [2,3,4,5]}, index: [:a, :b, :c, :d])
```
![init1](https://dl.dropboxusercontent.com/u/47978121/mikon/init1.png)

```ruby
df = Mikon::DataFrame.from_csv("~/data.csv")
```
![init2](https://dl.dropboxusercontent.com/u/47978121/mikon/init2.png)

### Basic data manipulating
```ruby
df[:value]
```
![init2](https://dl.dropboxusercontent.com/u/47978121/mikon/column_label.png)

```ruby
df[10..20]
```
![init2](https://dl.dropboxusercontent.com/u/47978121/mikon/row_num.png)

```ruby
df.head(2)
```
![head](https://dl.dropboxusercontent.com/u/47978121/mikon/head.png)

```ruby
df.tail(2)
```
![tail](https://dl.dropboxusercontent.com/u/47978121/mikon/tail.png)

### Row-based data manipulating

```ruby
df.select{value > 100}
```
![select](https://dl.dropboxusercontent.com/u/47978121/mikon/select.png)

```ruby
df2.map{b+1}.name(:c)
```
![map](https://dl.dropboxusercontent.com/u/47978121/mikon/map.png)

```ruby
foo = []
df.each{foo.push(2*a)}
p foo #-> [2,4,6]
```

```ruby
df.insert_column(:new_value){value * 2}
```
![insert_column](https://dl.dropboxusercontent.com/u/47978121/mikon/insert_column_row.png)

```ruby
df.any?{value >= 100} #-> true
df.all?{valu > 1} #-> false
```

### Column-based data manipulating
In most cases column-based manipulating is **faster than Row-based**.

```ruby
df2[:b] - df2[:a]
```
![column_base0](https://dl.dropboxusercontent.com/u/47978121/mikon/column-base0.png)

```ruby
df.insert_column(:new_value, df[:value]*2)
```
![column_base1](https://dl.dropboxusercontent.com/u/47978121/mikon/insert_column_row.png)

### Plotting
```ruby
df[:value].plot
```
![hist](https://dl.dropboxusercontent.com/u/47978121/mikon/hist.png)

### Plotting with Nyaplot
```ruby
require 'nyaplot'
plot = Nyaplot::Plot.new
plot.add_with_df(df, :histogram, :value)
plot
```
![hist](https://dl.dropboxusercontent.com/u/47978121/mikon/hist.png)

### Statistical with Statsample

`Mikon::Series` is compatible with `Statsample::Vector`, so most methods of Statsample can be applied to `Mikon::Series`.

```
require 'statsample'

Statsample::Analysis.store(Statsample::Test::T) do
  t_2 = Statsample::Test.t_two_samples_independent(df1[:value], df1[:new_value])
  summary t_2
end

Statsample::Analysis.run_batch
```
![statsample](https://dl.dropboxusercontent.com/u/47978121/mikon/statsample.png)

## License
The MIT License

## Acknowledgement
[Ruby Association Grant 2014](http://www.ruby.or.jp/en/news/20140805.html) has been earmarked for the development of Mikon.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/mikon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
