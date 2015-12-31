require 'set'

# https://gist.github.com/gareve/516ae518db928bdb40f2

STRAIGHTS = (?a..?z).to_a.join.split(/i|o|l/).flat_map { |x|
  x.chars.each_cons(3).to_a
}.map(&:join).map(&:freeze).freeze
ASCEND_PREFIX1 = Set.new(STRAIGHTS.map { |s| s[0].ord }).freeze

LETTERS = ((?a..?z).to_a - %w(i o l)).map(&:ord).freeze

def gen(prefix, length, repeats, repeat1, straight)
  if length == 8
    puts prefix.map(&:chr).join if repeats >= 2 && straight
    return
  end

  # Need nothing: 0
  # Need pair: 1 (copy prefix[-1])
  # Need two pairs: 3 (copy prefix[-1], aa)
  # Need straight:
  # * 1 if prefix[-2..-1] is ascend2
  # * 2 if prefix[-1] is ascend1
  # * else 3
  # Need straight and pair:
  # * 2 if prefix[-2..-1] is ascend2 (finish straight, copy for pair)
  # * 3 if prefix[-1] is ascend1 (pair chained into straight or vice versa)
  # * else 4
  # Need straight and two pair:
  # * 4 if prefix[-2..-1] is ascend2 (finish straight, copy for pair, aa)
  # * 4 if prefix[-1] is ascend1 (pair straight pair)
  # * else 5
  minimum_needed = [(2 - repeats) * 2 - 1, 0].max
  unless straight
    if ASCEND_PREFIX1.include?(prefix[-2]) && prefix[-2] + 1 == prefix[-1]
      minimum_needed += 1
    elsif ASCEND_PREFIX1.include?(prefix[-1])
      minimum_needed += (repeats == 0 ? 1 : 2)
    else
      minimum_needed += (repeats == 0 ? 2 : 3)
    end
  end

  return if length + minimum_needed > 8

  LETTERS.each { |l|
    if repeats < 2
      new_letter = repeat1.nil? || l != repeat1
      # Don't count zaaa as a pair, but do count zaaaa
      new_pair = new_letter && prefix[-1] == l && (prefix[-2] != l || prefix[-3] == l)
    else
      new_pair = false
    end

    gen(
      prefix + [l],
      length + 1,
      repeats + (new_pair ? 1 : 0),
      repeat1 || (new_pair ? l : nil),
      straight || (length >= 2 && prefix[-2] + 1 == prefix[-1] && prefix[-1] + 1 == l),
    )
  }
end

gen([], 0, 0, nil, false)
