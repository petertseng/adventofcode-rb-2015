class Interpreter
  def initialize(insts)
    @instructions = insts.freeze
  end

  def run(initial_state = {})
    registers = {a: 0, b: 0}.merge(initial_state)
    pc = -1
    while (op, args = @instructions[pc += 1])
      case op
      when :hlf; registers[args[0]] /= 2
      when :tpl; registers[args[0]] *= 3
      when :inc; registers[args[0]] += 1
      when :jmp; pc += args[0] - 1
      when :jie; pc += args[1] - 1 if registers[args[0]] % 2 == 0
      when :jio; pc += args[1] - 1 if registers[args[0]] == 1
      else raise "Unknown opcode #{op}"
      end
    end
    registers
  end
end

insts = ARGF.each_line.map { |l|
  cmd, args = l.strip.split(' ', 2)
  [cmd.to_sym, args.split(', ').map { |arg| arg.size == 1 ? arg.to_sym : Integer(arg) }].freeze
}.freeze

interpreter = Interpreter.new(insts)

puts interpreter.run[:b]
puts interpreter.run(a: 1)[:b]
