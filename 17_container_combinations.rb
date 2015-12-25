containers = ARGF.each_line.map(&method(:Integer))

# You'd think this is no better than the 2^n brute force solution
# (because of the two recursive calls to ways below).
# However, min_index only goes up and weight only goes down.
# So in fact this makes O(wn) calls (w is weight, n is number containers).
# The merge could take O(n) time though.
def ways(containers, weight, min_index, used)
  return {} if min_index >= containers.size
  return {used => 1} if weight == 0
  return {} if weight < 0
  if min_index == containers.size - 1
    # One container left
    weight == containers.last ? {used + 1 => 1} : {}
  else
    ways_without = ways(containers, weight, min_index + 1, used)
    ways_with = ways(containers, weight - containers[min_index], min_index + 1, used + 1)
    ways_without.merge(ways_with) { |_k, v1, v2| v1 + v2 }
  end
end

all_ways = ways(containers, 150, 0, 0)
puts all_ways.values.sum
puts all_ways[all_ways.keys.min]
