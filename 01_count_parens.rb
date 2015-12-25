puts ARGF.each_char.with_index.with_object([0]) { |(char, idx), answer|
  next if char == "\n"
  answer[0] += char == ?( ? 1 : -1
  answer[1] ||= idx + 1 if answer[0] == -1
}
