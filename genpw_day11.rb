ARGV << 'aaaaaaaa'
old_stdout = $stdout
$stdout = File.open('/dev/null', ?w)
require_relative '11_passwords'
$stdout = old_stdout

password = 'aaaaaaaa'
passwords = 0
first_two = 'aa'
per_letter = Hash.new(0)

using Password

while password.length <= 8
  password.next_password!
  break if password.length > 8
  passwords += 1
  if password[0..1] != first_two
    first_two = password[0..1]
    STDERR.puts first_two
  end
  per_letter[password[0]] += 1
end

puts passwords
puts per_letter.inspect
