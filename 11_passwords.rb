module Password; refine String do
  def confusing?
    match?(/i|o|l/)
  end

  def ascending?
    each_char.each_cons(3).any? { |a, b, c| b.ord - 1 == a.ord && c.ord - 2 == a.ord }
  end

  def two_repeats?
    match?(/(.)\1.*(.)\2/)
  end

  def good?
    !confusing? && ascending? && two_repeats?
  end
end; end

using Password

password = !ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read
password = password.dup

2.times {
  password.succ!
  password.succ! until password.good?
  puts password
}
