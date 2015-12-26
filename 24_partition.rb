require_relative 'lib/ckk'

verbose = ARGV.delete('-v')

weights = ARGF.each_line.map(&method(:Integer)).freeze

def min_needed(weights, target)
  # This is dodgy - a take_while with state
  weight_so_far = 0
  weights.sort.reverse.take_while { |n|
    weight_so_far += n
    weight_so_far < target
  }.size + 1
end

module DeleteFirst; refine Array do
  # Yes, so evil I am, redefining - on arrays.
  # It's needed in partition, because I want to delete exactly one element.
  # So, [1, 1, 2] - [1] should == [1, 2]
  def -(other)
    arr = dup
    other.each { |x| arr.delete_at(arr.index(x) || arr.length) }
    arr
  end
end; end

using DeleteFirst

def partition(weights, num_groups)
  sum = weights.sum
  each_group = sum / num_groups

  (min_needed(weights, each_group)..(weights.size / num_groups)).each { |n|
    winning_combos = weights.combination(n).select { |c|
      c.sum == each_group && CKK[num_groups - 1].new(weights - c).best == 0
    }
    next if winning_combos.empty?
    return winning_combos.min_by { |c| c.reduce(:*) }
  }
end

[3, 4].each { |n|
  best_weights = partition(weights, n)
  puts best_weights.reduce(:*)
  puts best_weights.to_s if verbose
}
