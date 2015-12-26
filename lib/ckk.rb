# CKK = Complete Karmarkar-Karp
#
# Papers:
# Multi-Way Number Partitioning by Korf
# A complete anytime algorithm for nnumber partitioning by Korf

class Ckk
  def initialize(weights)
    @weights = weights.freeze
    @best = Float::INFINITY
  end
end

class Ckk2 < Ckk
  def best(weights = @weights.dup, sum = @weights.sum)
    return weights.first if weights.size == 1

    # Shortcut: Largest number is >= the sum of the rest.
    # Put largest in one group, the rest in the other.
    greatest = weights.last
    sum_except_greatest = sum - greatest
    return greatest - sum_except_greatest if greatest >= sum_except_greatest

    a, b = weights.pop(2)
    new_sum = sum - a - b
    [b - a, a + b].map { |choice|
      result = best((weights + [choice]).sort, new_sum + choice)
      @best = [@best, result].min
      return @best if @best < 2
      result
    }.min
  end
end

class Ckk3 < Ckk
  def self.normalize(v)
    v.sort!
    v.reverse!
    norm = v.min
    v.map! { |w| w - norm }.pop
    v
  end

  def best(weights = initial_triples, sum = @weights.sum)
    return weights.first.first if weights.size == 1

    # Prune: What is the best we could possibly do at this branch?
    # Take the largest sum, assume we add nothing else to it.
    # Divide everything else evenly between two sets.
    greatest = weights.last.first
    sum_except_greatest = sum - greatest
    best_possible = greatest - sum_except_greatest / 2
    # If we've exceeded the best we've seen already, prune.
    return best_possible if best_possible > @best

    v1, v2 = weights.pop(2)
    a, b = v1
    x, y = v2
    new_sum = sum - a - b - x - y

    # Search in increasing order of largest sum.
    # Since normalization places the largest sum first,
    # that just means we do the standard #sort which sorts by first element.
    choices = [
      [a, b + y, x],
      [a + y, b, x],
      [a, b + x, y],
      [a + x, b, y],
      [a + y, b + x, 0],
      [a + x, b + y, 0],
    ].map { |v| self.class.normalize(v) }.uniq.sort

    choices.map { |v3|
      result = best((weights + [v3]).sort, new_sum + v3.sum)
      @best = [@best, result].min
      return @best if @best < 2
      result
    }.min
  end

  private

  def initial_triples
    @weights.map { |w| [w, 0] }
  end
end

CKK = {
  2 => Ckk2,
  3 => Ckk3,
}.freeze
