class Circuit
  def initialize(specs)
    @wires = {}
    @cache = {}
    specs.each { |s, t| self[t] = s }
  end

  def []=(target, spec)
    @wires[target] = spec.split
    @cache.clear
  end

  def [](name)
    # It's a number, just return it.
    as_i = name.to_i
    return as_i if as_i.to_s == name

    spec = @wires[name]

    @cache[name] ||= case spec.size
    when 1; self[spec.first]
    when 2
      raise "Unknown operator #{spec.first}" unless spec.first == 'NOT'
      ~self[spec.last] & 0xffff
    when 3
      operand1 = self[spec.first]
      operand2 = self[spec.last]
      case spec[1]
      when 'AND'; operand1 & operand2
      when 'OR'; operand1 | operand2
      when 'LSHIFT'; (operand1 << operand2) & 0xffff
      when 'RSHIFT'; operand1 >> operand2
      else raise "Unknown operator #{spec[1]}"
      end
    else raise "Unknown spec #{spec}"
    end
  end
end

# export for benchmark
@spec = ARGF.each_line(chomp: true).map { |l| l.split(' -> ').map(&:freeze).freeze }.freeze
circuit = Circuit.new(@spec)

a = p circuit[?a]
circuit[?b] = a.to_s
puts circuit[?a]
