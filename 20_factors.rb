target = Integer(!ARGV.empty? && ARGV.first.match?(/^\d+$/) ? ARGV.first : ARGF.read)

def give_gifts(target, multiplier, elf_limit: nil)
  max = (target / multiplier.to_f).ceil
  best = max
  gifts = Array.new(1 + max, 0)
  (1..max).each { |elf|
    nums = (elf..max).step(elf)
    nums = nums.take(elf_limit) if elf_limit
    nums.each_with_index { |house, i|
      total_gifts = (gifts[house] += elf)
      if total_gifts >= max
        best = [best, house].min
        # If it's my first house, no later elf can undercut me.
        return best if i == 0
      end
    }
  }
  best
end

# It's absoutely untenable to iterate every house and find its factors.
# Just iterate the elves.

puts give_gifts(target, 10)
puts give_gifts(target, 11, elf_limit: 50)
