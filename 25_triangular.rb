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

n = iterations(row: row, column: column)
x = SEED
n.times { x = x * BASE % MODULUS }
puts x
