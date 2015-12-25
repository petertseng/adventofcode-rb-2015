require 'benchmark'
require_relative '../12_json_numbers'

bench_candidates = %i(sums)

bench_candidates << def custom_parser_sums(json)
  total = 0

  nestable = []
  objs = [{sum: 0, red: false}]
  in_string = false

  red_start = 0
  red_good = 0

  num_buf = ''
  parse_number = -> {
    unless num_buf.empty?
      val = Integer(num_buf)
      total += val
      objs[-1][:sum] += val
    end
    num_buf.clear
  }

  json.each_char.with_index { |c, i|
    if in_string
      case c
      when ?r
        red_good += 1 if red_start == i - 1
      when ?e
        red_good += 1 if red_start == i - 2
      when ?d
        red_good += 1 if red_start == i - 3
      when ?"
        in_string = false
        # Assumes that there is never a key "red"
        objs[-1][:red] = true if red_good == 3 && red_start == i - 4 && nestable[-1] == :obj
      end
    else
      case c
      when ?{
        nestable << :obj
        objs << {sum: 0, red: false}
      when ?}
        parse_number[]
        raise 'bad close obj' unless nestable.pop == :obj
        obj = objs.pop
        objs[-1][:sum] += obj[:sum] unless obj[:red]
      when ?[
        nestable << :arr
      when ?]
        parse_number[]
        raise 'bad close arr' unless nestable.pop == :arr
      when ?"
        in_string = true
        red_good = 0
        red_start = i
      when ?,
        parse_number[]
      when ?-, ?0..?9
        num_buf << c
      when ?:, "\n"
        # nothing
      else
        raise "bad char #{c}"
      end
    end
  }

  raise 'bad json, unclosed obj' if objs.size != 1
  [total, objs[-1][:sum]]
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { results[f] = send(f, @json) }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
