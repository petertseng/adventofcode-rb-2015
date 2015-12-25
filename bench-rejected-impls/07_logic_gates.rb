require 'benchmark'
require_relative '../07_logic_gates'

class EagerCircuit
  def initialize(specs)
    dependents = Hash.new { |h, k| h[k] = [] }
    dependencies = {}
    ready_wires = []
    @known_wires = {}
    wire_specs = {}

    specs.each { |signal, wire|
      signal = signal.split
      deps = case signal.size
      when 1; [signal.first]
      when 2; [signal.last]
      when 3; [signal.first, signal.last]
      else raise "Unknown signal #{signal}"
      end

      non_nums = deps.reject { |dep| dep.to_i.to_s == dep }
      ready_wires << wire if non_nums.empty?
      wire_specs[wire] = signal.freeze
      non_nums.each { |dep| dependents[dep] << wire }
      dependencies[wire] = non_nums
    }

    ready_wires.each { |ready|
      spec = wire_specs[ready]
      @known_wires[ready] = case spec.size
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
      dependents[ready].each { |dependent|
        dependencies[dependent].delete(ready)
        ready_wires << dependent if dependencies[dependent].empty?
      }
    }
  end

  def [](wire)
    i = wire.to_i
    i.to_s == wire ? i : @known_wires[wire]
  end
end

module SelfRefHash
  def self.new(specs)
    specs = specs.map { |l, r| [r, l.split.map(&:freeze).freeze] }.to_h.freeze
    Hash.new { |h, k|
      as_i = k.to_i
      next as_i if as_i.to_s == k

      spec = specs.fetch(k)

      h[k] = case spec.size
      when 1; h[spec.first]
      when 2
        raise "Unknown operator #{spec.first}" unless spec.first == 'NOT'
        ~h[spec.last] & 0xffff
      when 3
        operand1 = h[spec.first]
        operand2 = h[spec.last]
        case spec[1]
        when 'AND'; operand1 & operand2
        when 'OR'; operand1 | operand2
        when 'LSHIFT'; (operand1 << operand2) & 0xffff
        when 'RSHIFT'; operand1 >> operand2
        else raise "Unknown operator #{spec[1]}"
        end
      else raise "Unknown spec #{spec}"
      end
    }
  end
end

bench_candidates = [Circuit, EagerCircuit, SelfRefHash]

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 100.times { results[f] = f.new(@spec)[?a] }}
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
