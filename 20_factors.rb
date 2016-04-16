require 'prime'

target = Integer(!ARGV.empty? && ARGV.first.match?(/^\d+$/) ? ARGV.first : ARGF.read)

# sigma1 calculates the sum of the factors of n.
def sigma1(n)
  Prime.prime_division(n).map { |prime, power|
    (0..power).sum { |pow| prime ** pow }
  }.reduce(1, :*)
end

def gifts_delivered(house, elf_limit)
  gifts = 0
  (1..(house ** 0.5)).each { |candidate|
    next if house % candidate != 0
    factor1 = candidate
    factor2 = house / candidate
    gifts += factor1 if factor2 < elf_limit
    gifts += factor2 if factor1 < elf_limit && factor1 != factor2
  }
  gifts
end

def smallest_greater_factorial(target, valid_bound)
  factorial = 2
  n = 2
  until valid_bound[factorial]
    n += 1
    factorial *= n
  end
  [factorial, n]
end

def house_upper_bound(target, elf_limit: nil)
  if elf_limit
    valid_bound = ->(x) { gifts_delivered(x, elf_limit) >= target }
  else
    valid_bound = ->(x) { sigma1(x) >= target }
  end
  bound, n = smallest_greater_factorial(target, valid_bound)

  # Try to decrease each factor as far as it can go:
  n.downto(1) { |factor_to_decrease|
    bound_without = bound / factor_to_decrease
    (1...factor_to_decrease).each { |replacement|
      new_bound = bound_without * replacement
      if valid_bound[new_bound]
        bound = new_bound
        break
      end
    }
  }

  bound
end

# Euler-Mascheroni constant
GAMMA = 0.57721566490153286060651209008240243104215933593992

def house_lower_bound(target, upper)
  # Robin's inequality:
  # \sigma(n) < e^\gamma n \log \log n
  # For sufficiently-large n (n > 5040) if Riemann hypothesis true.
  #
  # So the lower bound for target T is:
  # the first n for which e^\gamma n \log \log n > T
  #
  # n \log \log n > \frac{T}{e^\gamma}
  #
  # Since we are searching for a lower bound,
  # we can increase \log \log n to \log \log T
  #
  # n > \frac{T}{e^\gamma \log \log T}
  n = (target / (Math::E ** GAMMA * Math.log(Math.log(target)))).ceil

  # That n was approximate. Binary search to get a better one?
  n = (n..upper).bsearch { |i|
    Math::E ** GAMMA * i * Math.log(Math.log(i)) >= target
  }

  # Eh, if n was less than 5040 we probably aren't gaining much anyway.
  n > 5040 ? n : 1
end

def give_gifts(target, multiplier, elf_limit: nil)
  elf_value_needed = (target / multiplier.to_f).ceil

  # Find an upper bound on the house number.
  # This reduces the work we need to do in the loop.
  max_house = house_upper_bound(elf_value_needed, elf_limit: elf_limit)
  gifts = Array.new(1 + max_house, 0)

  min_house = house_lower_bound(elf_value_needed, max_house)

  (1..max_house).each { |elf|
    if elf < min_house
      skipped = (min_house - 1) / elf
      start_house = (skipped + 1) * elf
    else
      skipped = 0
      start_house = elf
    end

    nums = (start_house..max_house).step(elf)
    if elf_limit
      next if skipped >= elf_limit
      nums = nums.take(elf_limit - skipped)
    end

    nums.each_with_index { |house, i| gifts[house] += elf }

    # If it's my first house, no later elf can undercut me.
    return elf if elf >= min_house && gifts[elf] >= elf_value_needed
  }

  raise 'Impossible; some elf must have exceeded by now. Upper bound is wrong.'
end

# It's absoutely untenable to iterate every house and find its factors.
# Just iterate the elves.

puts give_gifts(target, 10)
puts give_gifts(target, 11, elf_limit: 50)
