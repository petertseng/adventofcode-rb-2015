module NiceStrings; refine String do
  def nice1?
    !match?(/ab|cd|pq|xy/) && match?(/(.)\1/) && match?(/(.*[aeiou]){3}/)
  end

  def nice2?
    match?(/(.).\1/) && match?(/(..).*\1/)
  end
end; end

using NiceStrings

lines = ARGF.map(&:freeze).freeze

puts lines.count(&:nice1?)
puts lines.count(&:nice2?)
