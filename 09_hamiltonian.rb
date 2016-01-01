require_relative 'lib/hamiltonian'

verbose = ARGV.delete('-v')

distances = ARGF.each_line.with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) { |l, dists|
  place1, to, place2, eq, dist = l.split
  raise "bad line #{l}" if to != 'to' || eq != ?=
  dist = Integer(dist)
  dists[place1][place2] = dist
  dists[place2][place1] = dist
}

Graph.paths(distances).values_at(:min, :max).each { |best|
  puts best[:cost]
  puts best[:path].join(', ') if verbose
}
