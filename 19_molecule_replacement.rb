require 'set'

replacements = ARGF.take_while { |l| !l.chomp.empty? }.each_with_object(Hash.new { |h, k| h[k] = [] }) { |line, h|
  from, to = line.split(' => ', 2)
  if from != ?e && !from.match?(/^[A-Z][a-z]*$/)
    raise "LHS #{from} was expected to have only one element"
  end
  h[from] << to.chomp.freeze
}.each_value(&:freeze).freeze

molecule = ARGF.read.freeze

puts replacements.each_with_object(Set.new) { |(k, vs), seen|
  molecule.scan(k) {
    i = Regexp.last_match.offset(0).first
    vs.each { |v|
      replaced = molecule.dup
      replaced[i, k.length] = v
      seen.add(replaced)
    }
  }
}.size

# A => BC increases size by 1
# A => BRnCAr increases size by 3
# A => BRnCYDAr increases size by 5
# A => BRnCYDYEAr increases size by 7
# We don't have to verify that all the rules follow this pattern,
# but let's do it just for fun.
bad_keys = %w(Rn Y Ar) & replacements.keys
raise "#{bad_keys} are expected to only appear on RHS" unless bad_keys.empty?

element = /([A-Z][a-z]*)/
val_regex = Regexp.union(*[
  /^#{element}{2}$/,
  /^#{element}Rn#{element}Ar$/,
  /^#{element}Rn#{element}Y#{element}Ar$/,
  /^#{element}Rn#{element}Y#{element}Y#{element}Ar$/,
])
bad_values = replacements.flat_map { |k, v| k == ?e ? [] : v.grep_v(val_regex) }
raise "#{bad_values.size}/#{replacements.values.flatten.size} bad values: #{bad_values}" unless bad_values.empty?

# So to count number of steps to go from e to the final molecule:
# Count the elements in the final molecule, subtract 1 (we start from e).
# Subtract 2 for every RnAr pair, subtract 2 for every Y
elements = molecule.count((?A..?Z).to_a.join)
# number of Ar should be equal to number of Rn
rn = molecule.scan('Rn').size
y = molecule.count(?Y)
ar = molecule.scan('Ar').size
raise "Rn (#{rn}) != Ar (#{ar})" unless rn == ar

e_increase = replacements[?e].map { |x| x.chars.count { |c| c == c.upcase } }.max - 1
puts elements - rn * 2 - y * 2 - e_increase
