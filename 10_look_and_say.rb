rounds = [40, 50]

x = !ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read

rounds.max.times { |i|
  x = x.scan(/((.)\2*)/).map { |list, char| "#{list.size}#{char}" }.join
  puts x.length if rounds.include?(i + 1)
}
