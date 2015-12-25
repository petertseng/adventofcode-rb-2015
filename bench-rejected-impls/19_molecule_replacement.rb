require 'benchmark'

# part 2 only

reverse_replacements = {}

*replacements, empty, molecule = ARGF.readlines(chomp: true).map(&:freeze)
raise "non-empty #{empty}" unless empty.empty?

replacements, reverse_replacements = replacements.each_with_object([Hash.new { |h, k| h[k] = [] }, {}]) { |line, (h, rev_h)|
  from, to = line.split(' => ', 2)
  if from != ?e && !from.match?(/^[A-Z][a-z]*$/)
    raise "LHS #{from} was expected to have only one element"
  end
  h[from] << to.freeze
  if existing = rev_h[to]
    raise "conflicting #{to} #{existing} vs #{from}"
  end
  rev_h[to] = from.freeze
}.map { |h| h.each_value(&:freeze).freeze }

molecule.freeze

bench_candidates = []

bench_candidates << def count(molecule, replacements, _)
  elements = molecule.count((?A..?Z).to_a.join)
  # number of Ar should be equal to number of Rn
  rn = molecule.scan('Rn').size
  y = molecule.count(?Y)
  ar = molecule.scan('Ar').size
  raise "Rn (#{rn}) != Ar (#{ar})" unless rn == ar

  e_increase = replacements[?e].map { |x| x.chars.count { |c| c == c.upcase } }.max - 1
  elements - rn * 2 - y * 2 - e_increase
end

bench_candidates << def replace_right(molecule, _, replacements)
  molecule = molecule.dup
  n = 0
  until molecule == ?e
    best = replacements.keys.max_by { |k| molecule.rindex(k)&.+(k.size) || -1 }
    return nil unless i = molecule.rindex(best)
    molecule[i, best.size] = replacements.fetch(best)
    n += 1
  end
  n
end

# Approaches that do not work (at least, not on all inputs):

bench_candidates << def replace_left(molecule, _, replacements)
  molecule = molecule.dup
  n = 0
  until molecule == ?e
    best = replacements.keys.min_by { |k| molecule.index(k) || molecule.size }
    return nil unless i = molecule.index(best)
    molecule[i, best.size] = replacements.fetch(best)
    n += 1
  end
  n
end

bench_candidates << def greedy_by_length(molecule, replacements, reverse_replacements)
  by_size = replacements.values.flatten.sort_by(&:size).reverse
  molecule = molecule.dup
  n = 0
  until molecule == ?e
    return nil unless best = by_size.find { |x| molecule.include?(x) }
    molecule[best] = reverse_replacements.fetch(best)
    n += 1
  end
  n
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 50.times { results[f] = send(f, molecule, replacements, reverse_replacements) }}
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
