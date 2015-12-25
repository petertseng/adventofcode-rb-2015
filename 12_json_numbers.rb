require 'json'

def sum_no_red(obj)
  case obj
  when Hash
    obj.values.include?('red') ? 0 : obj.values.sum { |x| sum_no_red(x) }
  when Array
    obj.sum { |x| sum_no_red(x) }
  when Integer
    obj
  when String
    0
  else raise "bad #{obj}"
  end
end

def sums(json)
  number = /-?\d+/
  [
    # Lazy, just look for all numbers.
    # This works as long as there isn't a number-in-a-string like "12"
    json.scan(number).sum(&method(:Integer)),
    sum_no_red(JSON.parse(json)),
  ]
end

json = ARGF.read.freeze
puts sums(json)

# export for benchmark
@json = json
