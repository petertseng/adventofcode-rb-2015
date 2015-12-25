require 'benchmark'

# part 2 only

replacements = Hash.new { |h, k| h[k] = [] }
reverse_replacements = {}
molecule = nil

ARGF.each_line(chomp: true) { |line|
  next if line.empty?
  parts = line.split(' => ', 2)
  if parts.size == 1
    raise "too many molecules #{molecule} vs #{parts.first}" if molecule
    molecule = parts.first
  else
    from, to = parts
    if from != ?e && !from.match?(/^[A-Z][a-z]*$/)
      raise "LHS #{from} was expected to have only one element"
    end
    replacements[from] << to.freeze
    if existing = reverse_replacements[to]
      raise "conflicting #{to} #{existing} vs #{from}"
    end
    reverse_replacements[to] = from.freeze
  end
}

replacements.each_value(&:freeze).freeze
reverse_replacements.freeze
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
