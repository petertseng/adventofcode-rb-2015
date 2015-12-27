SEED = 20151125
BASE = 252533
MODULUS = 33554393

nums = if ARGV.size >= 2 && ARGV.all? { |arg| arg.match?(/^\d+$/) }
  ARGV
else
  ARGF.read.scan(/\d+/)
end

row = Integer(nums[0])
column = Integer(nums[1])

def iterations(row: 1, column: 1)
  diagonal = row + column - 1
  (diagonal * diagonal + diagonal) / 2 - row
end

# Raise base to the power of exp by squaring.
# No longer necessary since Ruby added modular exponentiation in 2.5,
# and it is equally as fast.
# Keeping for posterity.
def mod_pow(base, exp, mod)
  return 1 if exp == 0

  odds = 1
  evens = base

  while exp >= 2
    odds = odds * evens % mod if exp % 2 == 1
    evens = evens * evens % mod
    exp /= 2
  end

  evens * odds % mod
end

n = iterations(row: row, column: column)
# This works because a*b%m == (a%m)*(b%m)%m
#puts SEED * mod_pow(BASE, n, MODULUS) % MODULUS
puts SEED * BASE.pow(n, MODULUS) % MODULUS
