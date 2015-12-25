class PeopleMatrix
  def initialize(pairs)
    @matrix = Hash.new { |h, k| h[k] = Hash.new(0) }

    pairs.each { |p1, p2, happiness|
      @matrix[p1][p2] += happiness
      @matrix[p2][p1] += happiness
    }
  end

  def best(circular: true)
    circular ? best_cycle : best_line
  end

  def score(seating, circular: true)
    circular ? score_cycle(seating) : score_line(seating)
  end

  private

  def best_cycle
    people = @matrix.keys
    first_person = people.shift
    # Total happiness is invariant to rotation.
    # So we eliminate rotations by fixing the first person.
    people.permutation.max_by { |seating|
      seating << first_person
      score_cycle(seating)
    }
  end

  def score_cycle(seating)
    seating.each_with_index.sum { |p1, i|
      p2 = seating[i - 1]
      @matrix[p1][p2]
    }
  end

  def best_line
    @matrix.keys.permutation.max_by { |seating| score_line(seating) }
  end

  def score_line(seating)
    seating.each_cons(2).sum { |p1, p2| @matrix[p1][p2] }
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

# Inserting "me" into the table with 0 score == a non-circular table.
[true, false].each { |circular|
  best = people.best(circular: circular)
  puts people.score(best, circular: circular)
  puts best.join(', ') if verbose
}
