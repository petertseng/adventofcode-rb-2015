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

  NEXT_STRAIGHT_START = {}
  STRAIGHT_FROM = {}
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
      ascents = []
      scan(ASCEND) { |s|
        ascents << [s, Regexp.last_match.offset(0).first]
      }

      pairs_needed = 0

      # SAFETY:
      # An unsafe pair is one that:
      # 1) Is the only pair in the password, and
      # 2) MUST be destroyed before finding another pair.
      # For pairs, this means any pairs starting three from the end, or later.
      # The xx in abcxx and abcxxd are unsafe, the xx in abcxxde is safe.
      # If we have an unsafe pair, the next password will not include it.
      # That means we can pretend it's not there.
      if pairs.empty? || pairs.size == 1 && pairs[0][1] > length - 4
        pairs_needed = 2
      elsif pairs.uniq(&:first).size < 2
        pairs_needed = 1
      end

      # Safety applies to straights/ascents too.
      # An unsafe ascent is alone and MUST be destroyed before finding a pair.
      # If need two pairs, tightest packing is abccdd: ascent starts at -6
      # If need one pair, tightest packing is abcc: ascent starts at -4
      # An ascent starting after these positions is unsafe.
      ascent_safe_threshold = pairs_needed >= 2 ? 6 : 4
      ascent_is_unsafe = ascents.size == 1 && ascents[0][1] > length - ascent_safe_threshold
      need_ascent = ascents.empty? || ascent_is_unsafe

      if pairs_needed == 2
        if need_ascent
          make_ascending_and_two_pairs!
        else
          # The first string that would generate two pairs:
          # One pair in the all-but-last-two prefix.
          # One pair in the suffix, the last two (aa)
          prefix = self[0...-2].make_pair!
          replace(prefix + 'aa')
        end
        next
      end

      if pairs_needed == 1
        if need_ascent
          make_ascending_and_pair!
        else
          make_pair!
        end
        next
      end

      # We do not need pairs.
      # If we have a straight (whether it's unsafe), this is a valid password.
      # Else, make one.
      if ascents.empty?
        # If there are exactly two pairs and one is too close to the end,
        # at least one will be destroyed before finding a straight.
        #
        # e.g. abbzz -> abcaa destroys the bb pair.
        # If the other pair is elsewhere, such as bbeaa,
        # clearly you can't make the straight without destroying the aa pair.
        #
        # aadcabbc also clearly requires destroying the bb pair.
        #
        # This rule is inapplicable with three pairs.
        # The last one can be safely destroyed such as aabbaacd -> aabbabca
        if pairs.size == 2 && pairs[-1][1] > length - 4
          make_ascending_and_pair!
        else
          make_ascending!
        end
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

  # Increments self at least once.
  # Stops upon reaching the lowest lexicographic string that has a pair and straight.
  def make_ascending_and_pair!
    succ!
    unconfuse!

    # For an early return to happen, at least three characters must change.
    # Obviously you can't do it with just one.
    # You can't do it with just two: the straight blocks the pair.
    # abbz -> abca (you can't get to abcc)
    # Anything else such as abbzz -> abcaa already has two pairs!

    # Can't make pair and straight only changing one character.

    # Changes involving the second-to-last character:
    if make_straight_end!(-2)
      # Becomes end of straight and first of pair.
      self[-1] = self[-2]
      return self
    end

    # Changes involving the third-to-last character:
    if self[-4] > self[-3] && self[-4].match?(ASCEND_PREFIX1)
      # Becomes second of pair and start of straight.
      self[-3..-1] = straight_from(self[-4])
      return self
    elsif make_straight_end!(-3)
      self[-2..-1] = 'aa'
      return self
    elsif make_straight_middle!(-3)
      self[-1] = self[-2]
      return self
    end

    # Can't be first of pair; would leave no room for straight.

    # Changes involving the fourth-to-last character:
    choices = straight_choices(-4)
    choices[:second] = "#{self[-5]}abc" if self[-5] > self[-4]
    choices[:end] << 'aaa' if choices[:end]
    choices[:middle] << 'aa' if choices[:middle]
    # Given a straight xyz, we could make a pair with xxyz or xyzz.
    # xxyz wins lexicographically.
    if (b = choices[:begin])
      choices[:begin] = "#{b[0]}#{b}"
    end

    unless choices.empty?
      self[-4..-1] = choices.values.min
      return self
    end

    # Changes involving the fifth-to-last character:
    prefix = self[0...-4].succ.unconfuse!
    replace(prefix + (prefix.match?(ASCEND) ? 'aaaa' : 'aabc'))

    self
  end

  # Increments self at least once.
  # Stops upon reaching the lowest lexicographic string that has two pairs and a straight.
  def make_ascending_and_two_pairs!
    succ!
    unconfuse!

    # Don't need to check for completion, you can't get this in one succ.
    # At least four characters need to change (see below).
    # So that'd be similar to xybcczzz -> xybcdaaa, but that's only one pair.
    # As for xbcczzzz -> xbcdaaaa, that had two safe pairs.
    # So this function doesn't get called on input like xbcczzzz.

    # First-Third: Impossible; not enough characters to work with.
    # * If third char ends a straight, no room for two pairs after.
    # * If third char ends a pair, no room for both a straight and a pair after.

    # Changes involving the fourth-to-last character:
    if self[-5] > self[-4] && self[-5].match?(ASCEND_PREFIX1)
      # Becomes end of straight and first of pair.
      self[-4..-2] = straight_from(self[-5])
      self[-1] = self[-2]
      return self
    elsif make_straight_end!(-4)
      self[-3..-1] = "#{self[-4]}aa"
      return self
    end

    # Can't be mid of straight, no room for two pairs after.
    # Can't be first of pair, no room for both a straight and a pair after.

    # Changes involving the fifth-to-last character:
    choices = straight_choices(-5)
    choices[:second] = "#{self[-6]}aabc" if self[-6] > self[-5]
    choices[:end] << 'aaaa' if choices[:end]
    choices[:middle] << "#{choices[:middle][-1]}aa" if choices[:middle]
    # Given a straight xyz, the only way to make two pairs is xxyzz
    # The only other case is if xyzza works (if the character before were x)
    # But in either case xxyzz is superior.
    if (b = choices[:begin])
      choices[:begin] = "#{b[0]}#{b}#{b[-1]}"
    end

    unless choices.empty?
      self[-5..-1] = choices.values.min
      return self
    end

    # Changes involving the sixth-to-last character:
    prefix = self[0...-5].succ.unconfuse!
    self[0...-5] = prefix

    if prefix.match?(ASCEND)
      self[-5..-1] = 'aaaaa'
    elsif prefix.match?(PAIR) || prefix[-1] == ?a
      self[-5..-1] = 'aaabc'
    else
      self[-5..-1] = 'aabcc'
    end

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
    NEXT_STRAIGHT_START[char] ||= begin
      next_char = char.succ
      next_char.succ! until next_char.match?(ASCEND_PREFIX1)
      next_char.freeze
    end
  end

  def straight_from(char)
    STRAIGHT_FROM[char] ||= begin
      s = char.dup
      s << (second = s.succ)
      s << second.succ
      s.freeze
    end
  end
end; end

using Password

password = !ARGV.empty? && !File.exist?(ARGV.first) ? ARGV.first : ARGF.read
password = password.dup

2.times {
  password = password.next_password
  puts password
}
