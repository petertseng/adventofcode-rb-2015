module Password
  PAIR = /(.)\1/

  STRAIGHTS = (?a..?z).to_a.join.split(/i|o|l/).flat_map { |x|
    x.chars.each_cons(3).to_a
  }.map(&:join).map(&:freeze).freeze

  ASCEND = Regexp.union(*STRAIGHTS)
  # Strings that can be the prefix of a straight
  ASCEND_PREFIX2 = Regexp.union(*STRAIGHTS.map { |s| s[0..1] })
  # Strings that can be the first character of a straight
  ASCEND_PREFIX1 = Regexp.union(*STRAIGHTS.map { |s| s[0] })
end

module Password; refine String do
  def next_password
    dup.next_password!
  end

  def next_password!
    succ!
    unconfuse!

    loop {
      pairs = []
      scan(PAIR) { |s|
        pairs << [s, Regexp.last_match.offset(0).first]
      }

      # SAFETY:
      # An unsafe pair is one that:
      # 1) Is the only pair in the password, and
      # 2) MUST be destroyed before finding another pair.
      # For pairs, this means any pairs starting three from the end, or later.
      # The xx in abcxx and abcxxd are unsafe, the xx in abcxxde is safe.
      # If we have an unsafe pair, the next password will not include it.
      # That means we can pretend it's not there.
      if pairs.empty? || pairs.size == 1 && pairs[0][1] > length - 4
        # The first string that would generate two pairs:
        # One pair in the all-but-last-two prefix.
        # One pair in the suffix, the last two (aa)
        prefix = self[0...-2].make_pair!
        replace(prefix + 'aa')
        next
      elsif pairs.uniq(&:first).size < 2
        # Just need one more pair.
        make_pair!
        next
      end

      unless match?(ASCEND)
        make_ascending!
        next
      end

      return self
    }
  end

  def succ_no_confuse
    ans = succ
    ans.confusing? ? ans.succ : ans
  end

  def confusing?
    self == ?i || self == ?o || self == ?l
  end

  def unconfuse!
    if (i = index(/i|o|l/))
      succ_index!(i)
    end
    self
  end

  # Increments self at least once.
  # Stops upon reaching the lowest lexicographic string that has a pair.
  # (This one's public because it gets called on a prefix to make two pairs)
  def make_pair!
    last_was_z = self[-1] == ?z

    succ!
    unconfuse!

    # Return now for cbz -> cca but NOT aaa -> aab
    return self if last_was_z && self[-3] == self[-2]

    # We don't need to check more than 3 chars.
    # The only way >= 3 chars change is if at least the last two chars are z.
    # In that case, succ! would give a string ending in aa, and that's a pair.
    # For the same reason, it's OK that we didn't return early for dczz -> ddaa.

    if self[-2] > self[-1]
      # Easy case: only the last char changes.
      # For example, cba -> cbb
      self[-1] = self[-2]
    elsif self[-2] < self[-1]
      # The last two chars have to change. Two cases:
      if self[-3] == self[-2].succ_no_confuse
        # The third-to-last and second-to-last character make a pair.
        # For example, cbc -> cca (which comes before ccc)
        self[-2] = self[-3]
        self[-1] = ?a
      else
        # The second-to-last and last character make a pair.
        # For example, cab -> cbb (which comes before cca)
        next_char = self[-2].succ_no_confuse
        self[-2..-1] = next_char * 2
        # It's impossible for second-to-last to be 'z'.
        # No letter sorts after 'z'.
        # So we won't accidentally turn a 'z' into an 'aa' this way.
      end
    end

    self
  end

  private

  # Increments the string at the specified index.
  # All later indices will change to "a".
  def succ_index!(i)
    self[i] = self[i].succ
    self[(i + 1)..-1] = ?a * (length - 1 - i)
    self
  end

  # Increments self at least once.
  # Stops upon reaching the lowest lexicographic string that ascends.
  def make_ascending!
    succ!
    unconfuse!

    return self if match?(ASCEND)

    # Changes involving the last character:
    return self if make_straight_end!(-1)

    # Changes involving the second-to-last character:
    if make_straight_end!(-2)
      self[-1] = ?a
      return self
    end
    return self if make_straight_middle!(-2)

    # Changes involving the third-to-last character:
    choices = straight_choices(-3)
    choices[:end] << 'aa' if choices[:end]
    choices[:middle] << 'a' if choices[:middle]

    unless choices.empty?
      self[-3..-1] = choices.values.min
      return self
    end

    # Changes involving the fourth-to-last character:
    prefix = self[0...-3].succ.unconfuse!
    replace(prefix + (prefix.match?(ASCEND) ? 'aaa' : 'abc'))

    self
  end

  # Given an index that needs to increment its character,
  # returns Hash[Position => String] of possible straight choices.
  # Position is :begin | :middle | :end
  # Strings only contain as many characters as required to make the straight.
  # Depending on the application, you may need to post-process these.
  def straight_choices(idx)
    choices = {}

    if self[idx - 1] >= self[idx]
      if self[(idx - 2)..(idx - 1)].match?(ASCEND_PREFIX2)
        choices[:end] = self[idx - 1].succ
      end
      if increments_to_straight_middle?(idx)
        s = self[idx - 1].succ
        s << s.succ
        choices[:middle] = s
      end
    end

    if self[idx] < ?x
      next_char = next_straight_start(self[idx])
      choices[:begin] = straight_from(next_char)
    end

    choices
  end

  # If possible, makes idx the middle of a straight.
  # This modifies idx + 1.
  # Returns self on success, nil on failure.
  def make_straight_middle!(idx)
    if self[idx - 1] >= self[idx] && increments_to_straight_middle?(idx)
      self[idx] = self[idx - 1].succ
      self[idx + 1] = self[idx].succ
      self
    end
  end

  # If possible, makes idx the end of a straight.
  # Returns self on success, nil on failure.
  def make_straight_end!(idx)
    if self[idx - 1] >= self[idx] && self[(idx - 2)..(idx - 1)].match?(ASCEND_PREFIX2)
      self[idx] = self[idx - 1].succ
      self
    end
  end

  # Could this string start a straight at idx-1 if idx is incremented?
  def increments_to_straight_middle?(idx)
    c = self[idx - 1]
    # If first char is x, need to make sure idx is not y or z.
    # If it gets incremented, we can't make a straight.
    c.match?(ASCEND_PREFIX1) && (c != ?x || self[idx] < ?y)
  end

  def next_straight_start(char)
    next_char = char.succ
    next_char.succ! until next_char.match?(ASCEND_PREFIX1)
    next_char
  end

  def straight_from(char)
    s = char
    s << (second = s.succ)
    s << second.succ
    s
  end
end; end

using Password

password = !ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read
password = password.dup

2.times {
  password = password.next_password
  puts password
}
