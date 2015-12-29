require 'stringio'

old_stdout = $stdout
capture = StringIO.new
$stdout = capture

require_relative '11_passwords'

$stdout = old_stdout

expected = "cqjxxyzz\ncqkaabcc\n"
observed = capture.string
raise "expected #{expected.split} got #{observed.split}" unless observed == expected

using Password

tries = [
  # Disregard pair that was already there (no z rollover false negative)
  %w(aaa abb),

  # Z rollover, one z
  %w(cbz cca),

  # Z rollover, pair z
  %w(dbzz dcaa),

  # Just change last character.
  %w(xba xbb),

  # Change two characters easy case.
  %w(xbd xcc),

  # Change two characters, pair in front.
  %w(cbc cca),

  # Change two characters, pair in front with skip.
  %w(jhj jja),

  # Change two characters, no pair in front.
  %w(cab cbb),
].to_h

result = tries.map { |input, expected|
  old_password = input.dup
  observed = input.dup
  observed.make_pair!
  puts "#{old_password} -> #{observed} (want #{expected}) #{expected == observed}"
  expected == observed
}
puts "All make_pair pass: #{result.count(true)}/#{result.size} #{result.all?}"
raise unless result.all?
puts

tries = [
  # Stop if Z rollover gives straight.
  %w(bccz bcda),

  # Just change last character.
  %w(xbca xbcd),

  # Change last two, straight from -4
  %w(deaa defa),
  %w(xdeaa xdefa),

  # Change last two, straight from -3
  %w(eea efg),
  %w(xeea xefg),

  # Increment -3, straight from -5
  %w(abbdd abcaa),

  # Increment -3, straight from -4
  %w(bbdd bcda),
  %w(xbbdd xbcda),

  # Increment -3, straight from -3
  %w(xbda xcde),
  %w(xbce xcde),
  %w(xxbda xxcde),
  %w(xxbce xxcde),

  # Arbitrarily increase -3, straight from -5
  %w(fgfha fghaa),

  # "Arbitrarily increase -3, straight from -4" can't happen.
  # I'll always be able to increment -3 if -4..-2 could be a straight.

  # Arbitrarily increase -3 past unusables
  %w(zgaa zpqr),

  # Arbitrarily increase -3, do not take possible straight from -5
  %w(vwgaa vwpqr),

  # Fourth prereq: xyz is OK.
  %w(abbxya abbxyz),
  %w(aabxya aabxyz),

  # Increment fourth, resulting in straight
  %w(abbxyz abcaaa),
  %w(abbyaa abcaaa),
  %w(abbzaa abcaaa),

  # Increment fourth, no straight
  %w(aabxyz aacabc),
  %w(aabyaa aacabc),
  %w(aabzaa aacabc),

  # Increment fourth past confusing
  %w(aahzaa aajabc),
  %w(ahzzaa ajaabc),
].to_h

result = tries.map { |input, expected|
  old_password = input.dup
  observed = input.dup
  observed.make_ascending!
  puts "#{old_password} -> #{observed} (want #{expected}) #{expected == observed}"
  expected == observed
}
puts "All make_ascending pass: #{result.count(true)}/#{result.size} #{result.all?}"
raise unless result.all?
puts

STRAIGHTS = (?a..?z).to_a.join.split(/i|o|l/).flat_map { |x|
  x.chars.each_cons(3).to_a
}.map(&:join).map(&:freeze).freeze
ASCEND = Regexp.union(*STRAIGHTS)
LETTERS = (?a..?z).to_a - %w(i o l)
CONFUSING = /i|o|l/

10000.times { |i|
  str = (0...10).map { LETTERS.to_a[rand(23)] }.join
  s1 = str.dup
  s2 = str.dup
  s1.succ!
  s1.succ! until s1 =~ ASCEND && s1 !~ CONFUSING
  s2.make_ascending!
  raise "nope, from #{str} manual #{s1} automatic #{s2}" unless s1 == s2
  puts "#{i + 1}" if (i + 1) % 1000 == 0
}
