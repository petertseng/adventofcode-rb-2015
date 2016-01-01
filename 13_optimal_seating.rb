require_relative 'lib/hamiltonian'

class PeopleMatrix
  def initialize(pairs)
    @matrix = Hash.new { |h, k| h[k] = Hash.new(0) }

    pairs.each { |p1, p2, happiness|
      @matrix[p1][p2] += happiness
      @matrix[p2][p1] += happiness
    }

    @min_value = @matrix.map { |k, v| v.values.min }.min
    @matrix.each_value { |v| v.each_key { |k| v[k] -= @min_value } }
  end

  def bests
    Graph.maxes(@matrix).each { |k, v|
      edges = @matrix.size - (k == :path ? 1 : 0)
      v[:cost] += @min_value * edges
    }
  end
end

LINE = /^(.+) would (gain|lose) (\d+) happiness units by sitting next to (.+)\.$/

verbose = ARGV.delete('-v')

people = PeopleMatrix.new(ARGF.each_line.map { |line|
  p1, polarity, happiness, p2 = LINE.match(line).captures
  happiness = Integer(happiness)
  happiness *= -1 if polarity == 'lose'
  [p1, p2, happiness]
})

people.bests.values_at(:cycle, :path).each { |best|
  puts best[:cost]
  puts best[:path].join(', ') if verbose
}
