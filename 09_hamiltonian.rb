verbose = ARGV.delete('-v')

distances = ARGF.each_line.with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) { |l, dists|
  place1, to, place2, eq, dist = l.split
  raise "bad line #{l}" if to != 'to' || eq != ?=
  dist = Integer(dist)
  dists[place1][place2] = dist
  dists[place2][place1] = dist
}

distances.keys.permutation.with_object(
  min: {dist: Float::INFINITY, path: [], accept: :<.to_proc},
  max: {dist: 0, path: [], accept: :>.to_proc},
) { |p, answer|
  dist = p.each_cons(2).sum { |place1, place2|
    distances[place1][place2]
  }
  answer.values.each { |ans|
    if ans[:accept][dist, ans[:dist]]
      ans[:dist] = dist
      ans[:path] = p
    end
  }
}.each_value { |v|
  puts v[:dist]
  puts v[:path].join(', ') if verbose
}
