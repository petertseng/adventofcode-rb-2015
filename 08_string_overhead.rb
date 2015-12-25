CHAR = /\\"|\\\\|\\x..|[^\\]/

def literal_overhead(str)
  # exclude quotes, then count chars inside quotes.
  str.size - str[1...-1].scan(CHAR).size
end

def encoded_overhead(str)
  # 2 for the quotes, then escape any quotes or slashes by prepending a slash
  2 + str.count(?") + str.count(?\\)
end

input = ARGF.each_line(chomp: true).map(&:freeze).freeze

puts input.sum { |i| literal_overhead(i) }
puts input.sum { |i| encoded_overhead(i) }
