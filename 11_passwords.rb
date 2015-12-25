module Password
  ASCEND = Regexp.union(*(?a..?z).each_cons(3).map(&:join))
end

module Password; refine String do
  def confusing?
    match?(/i|o|l/)
  end

  def ascending?
    match?(ASCEND)
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
