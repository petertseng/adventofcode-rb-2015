DESIRES = {
  children: [3, :==.to_proc],
  cats: [7, :>.to_proc],
  samoyeds: [2, :==.to_proc],
  pomeranians: [3, :<.to_proc],
  akitas: [0, :==.to_proc],
  vizslas: [0, :==.to_proc],
  goldfish: [5, :<.to_proc],
  trees: [3, :>.to_proc],
  cars: [2, :==.to_proc],
  perfumes: [1, :==.to_proc],
}.freeze
DESIRES.each_value(&:freeze)

puts ARGF.each_line.with_object([[], []]) { |line, found|
  name, traits = line.split(': ', 2)
  sue_id = Integer(name.delete_prefix('Sue '))
  traits = traits.split(', ').map { |trait|
    key, value = trait.split(': ')
    [key.to_sym, Integer(value)]
  }

  found[0] << sue_id if traits.all? { |key, value| DESIRES[key].first == value }
  found[1] << sue_id if traits.all? { |key, value|
    thresh, func = DESIRES[key]
    func[value, thresh]
  }
}
