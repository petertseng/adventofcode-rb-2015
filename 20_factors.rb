target = Integer(!ARGV.empty? && ARGV.first.match?(/^\d+$/) ? ARGV.first : ARGF.read)

PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47].reverse.freeze

# askalski's tip:
# https://www.reddit.com/r/adventofcode/comments/po1zel/comment/hd1esc2
# > The idea behind the recursion is to try including different powers of each prime `p` in the house number,
# > then solve the subproblem of `ceil(goal / (1 + p + ... + p^n))` using only those primes smaller than `p`.
@cache = {}
def sum_exceeds(goal, primes = PRIMES)
  return goal if primes.empty?

  @cache[[goal, primes[0]]] ||= begin
    # try skipping this prime
    best = sum_exceeds(goal, primes[1..])

    prime = primes[0]
    prime_power = 1
    prime_sum = 1

    while prime_sum < goal
      prime_power *= prime
      prime_sum += prime_power

      # subproblem: ceil(goal/prime_sum) using only primes less than prime
      subgoal = (goal + prime_sum - 1) / prime_sum
      best = [best, prime_power * sum_exceeds(subgoal, primes[1..])].min
    end

    best
  end
end

puts house1 = sum_exceeds(target / 10)

# each elf only visits 50 houses,
# so at most 50 elves visit a house: house / 1, house / 2, house / 3, etc.
# so, testing a house is relatively fast.
# And I'll go out on a limb and say that if a number isn't divisible by all of 2, 3, 5, 7,
# it hasn't got much hope.
[2, 3, 5, 7].each { |d| raise "unusual part 1 answer isn't divisible by #{d}" if house1 % d != 0 }
good2 = ->house { 11 * (1..50).sum { |d| house % d == 0 ? house / d : 0 } >= target }
puts (good2[house1] ? 0 : house1).step(by: 2 * 3 * 5 * 7).find(&good2)
