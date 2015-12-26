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

def partition(weights, num_groups)
  sum = weights.sum
  each_group = sum / num_groups

  (min_needed(weights, each_group)..(weights.size / num_groups)).each { |n|
    # Is it sound to assume that the other presents can be divided?!
    winning_combos = weights.combination(n).select { |c| c.sum == each_group }
    next if winning_combos.empty?
    return winning_combos.min_by { |c| c.reduce(:*) }
  }
end

[3, 4].each { |n|
  best_weights = partition(weights, n)
  puts best_weights.reduce(:*)
  puts best_weights.to_s if verbose
}
