require 'digest'

input = (!ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read).freeze
n = 0
zeroes = [5, 6]

num_zeroes = zeroes.shift
target_prefix = ?0 * num_zeroes

while num_zeroes
  md5 = Digest::MD5.hexdigest(input + n.to_s)
  if md5.start_with?(target_prefix)
    puts n
    num_zeroes = zeroes.shift
    target_prefix = ?0 * num_zeroes if num_zeroes
  else
    n += 1
  end
end
