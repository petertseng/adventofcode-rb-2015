def paper(dimensions)
  sides = dimensions.combination(2).map { |c| c.reduce(:*) }
  sides.sum * 2 + sides.min
end

def ribbon(dimensions)
  dimensions.min(2).sum * 2 + dimensions.reduce(:*)
end

dimensions = ARGF.map { |line|
  line.split(?x).map(&method(:Integer)).freeze
}.freeze

puts dimensions.sum { |d| paper(d) }
puts dimensions.sum { |d| ribbon(d) }
