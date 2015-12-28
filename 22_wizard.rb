EXAMPLES = ARGV.delete('-d')
VERBOSE = ARGV.delete('-v')
SEARCH_BOSS_HP = ARGV.delete('-b')

nums = if ARGV.size >= 2 && ARGV.all? { |arg| arg.match?(/^\d+$/) }
  ARGV
else
  ARGF.read.scan(/\d+/)
end

BOSS_HP = Integer(nums[0])
BOSS_DAMAGE = Integer(nums[1])

class Game
  # As long as hashes have deterministic enumeration order,
  # the order in which spells are listed here affects search priority.
  # This order was roughly determined to be pretty good.
  # At least, much better than magic missile in highest priority.
  COSTS = {
    poison: 173,
    shield: 113,
    recharge: 229,
    magic_missile: 53,
    drain: 73,
  }

  TIMER_BITS = 9

  def initialize(
    my_hp: 50,
    my_mp: 500,
    boss_hp: BOSS_HP,
    boss_damage: BOSS_DAMAGE,
    hard: false,
    verbose: false
  )
    @my_hp = my_hp
    @my_mp = my_mp
    @boss_hp = boss_hp
    @boss_damage = boss_damage
    @hard = hard
    @verbose = verbose
    @shield_time = 0
    @poison_time = 0
    @recharge_time = 0

    # Since cast_spell assumes start-of-turn effects have already applied,
    # we need to remove remove hard mode HP now.
    # There can be no timers, so we don't need to tick_timers
    @my_hp -= 1 if @hard

    # Offsets for storing game state: My HP comes after timers and boss HP.
    # We need to calculate how many bits the boss's HP needs.
    @hp_offset = TIMER_BITS + boss_hp.bit_length
    # Drain may heal our HP, but at most we drain HP equal to the boss's HP.
    # +1 if the boss's HP is odd (shouldn't matter, boss would be dead).
    # And the boss is dealing at least 1 damage per drain we do.
    # So we can halve the max drain (+2 for if the boss dies on last one).
    max_hp_bits = (my_hp + 2 + boss_hp / 2).bit_length
    @mp_offset = @hp_offset + max_hp_bits
  end

  def to_i
    # 3 shield, 3 poison, 3 recharge since their timers are all < 8
    # Bit widths for my HP and boss HP were calculated in initialize.
    # MP goes in the most significant position.
    # (My MP is potentially unbounded, but Recharge-only battles are losses)
    timers = @shield_time << 6 | @poison_time << 3 | @recharge_time
    @my_mp << @mp_offset | @my_hp << @hp_offset | @boss_hp << TIMER_BITS | timers
  end

  def to_s
    me = "Me #@my_hp HP #@my_mp MP"
    me << " #@shield_time Shield" if @shield_time > 0
    me << " #@recharge_time Recharge" if @recharge_time > 0
    boss = "Boss #@boss_hp HP"
    boss << " #@poison_time Poison" if @poison_time > 0
    "#{me} vs #{boss}"
  end

  def cast_spell(spell)
    apply_spell_effect(spell)
    return winner if winner

    puts "\n-- Boss turn --\n#{to_s}" if @verbose
    tick_timers
    return winner if winner

    boss_attack
    return winner if winner

    puts "\n-- Player turn --\n#{to_s}" if @verbose
    if @hard
      @my_hp -= 1
      puts "Hard mode: My HP -> #@my_hp" if @verbose
    end
    tick_timers
    winner
  end

  def legal_spells
    legal = COSTS.select { |spell, cost| cost <= @my_mp }
    legal.delete(:shield) if @shield_time > 0
    legal.delete(:poison) if @poison_time > 0
    legal.delete(:recharge) if @recharge_time > 0
    legal
  end

  def winner
    return :boss if @my_hp <= 0
    return :me if @boss_hp <= 0
    nil
  end

  # A lower bound of how much it would cost to kill the boss.
  # This may not even be *achievable*, but it's a lower bound.
  # It is used to determine when we can't beat the current best.
  def min_cost_to_kill
    after_poison = @boss_hp - @poison_time * 3
    return 0 if after_poison <= 0
    poisons, after_poison = after_poison.divmod(18)
    missiles = (after_poison / 4.0).ceil

    poison_cost = COSTS[:poison]
    poisons_cost = poisons * poison_cost
    missile_cost = missiles * COSTS[:magic_missile]
    poisons_cost + [missile_cost, poison_cost].min
  end

  private

  def tick_timers
    if @shield_time > 0
      @shield_time -= 1
      puts "Shield: timer -> #@shield_time" if @verbose
    end
    if @recharge_time > 0
      @recharge_time -= 1
      @my_mp += 101
      puts "Recharge: My MP -> #@my_mp, timer -> #@recharge_time" if @verbose
    end
    if @poison_time > 0
      @poison_time -= 1
      @boss_hp -= 3
      puts "Poison: Boss HP -> #@boss_hp, timer -> #@poison_time" if @verbose
    end
  end

  def apply_spell_effect(spell)
    cost = COSTS.fetch(spell)
    raise "Can't cast #{spell} costing #{cost} MP with only #@my_mp MP" if cost > @my_mp
    @my_mp -= cost
    puts "Cast #{spell}: My MP -> #@my_mp" if @verbose

    case spell
    when :magic_missile
      @boss_hp -= 4
      puts "#{spell}: Boss HP -> #@boss_hp" if @verbose
    when :drain
      @boss_hp -= 2
      @my_hp += 2
      puts "#{spell}: Boss HP -> #@boss_hp, my HP -> #@my_hp" if @verbose
    when :shield
      raise "can't cast #{spell} for #@shield_time turns" if @shield_time > 0
      @shield_time = 6
    when :poison
      raise "can't cast #{spell} for #@poison_time turns" if @poison_time > 0
      @poison_time = 6
    when :recharge
      raise "can't cast #{spell} for #@recharge_time turns" if @recharge_time > 0
      @recharge_time = 5
    end
  end

  def boss_attack
    damage = [@boss_damage - (@shield_time > 0 ? 7 : 0), 1].max
    @my_hp -= damage
    puts "Boss attack for #{damage} damage: My HP -> #@my_hp" if @verbose
  end
end

if EXAMPLES
  # Example 1
  puts "\e[1;31mExample game 1\e[0m"
  g = Game.new(my_hp: 10, my_mp: 250, boss_hp: 13, boss_damage: 8, verbose: true)
  g.cast_spell(:poison)
  g.cast_spell(:magic_missile)
  puts "WINNER! #{g.winner}"
  puts

  # Example 2
  puts "\e[1;31mExample game 2\e[0m"
  g = Game.new(my_hp: 10, my_mp: 250, boss_hp: 14, boss_damage: 8, verbose: true)
  g.cast_spell(:recharge)
  g.cast_spell(:shield)
  g.cast_spell(:drain)
  g.cast_spell(:poison)
  g.cast_spell(:magic_missile)
  puts "WINNER! #{g.winner}"
  puts
end

class Search
  attr_reader :best_list

  def initialize(game, verbose: false)
    @game = game.dup
    @best_cost = Float::INFINITY
    @best_list = []
    @seen = Hash.new { |h, k| h[k] = {} }
    @max_prunes = 0
    @seen_prunes = 0
    @spells_cast = 0
    @verbose = verbose
  end

  def best(game = @game, spells_so_far: [], cost_so_far: 0, turn: 1)
    # Prune: We can't possibly do better than the current best.
    # This is about a 2x speedup (0.45 seconds -> 0.2 seconds)
    if game.min_cost_to_kill + cost_so_far > @best_cost
      puts "Best so far is #@best_cost, pruning a #{cost_so_far} + #{game.min_cost_to_kill}" if @verbose
      @max_prunes += 1
      return Float::INFINITY
    end

    # Prune: Seen this state already.
    # This is about a 50x speedup (10 seconds -> 0.2 seconds).
    if (prev_cost = @seen[turn][game.to_i]) && prev_cost <= cost_so_far
      puts "Seen #{game} at turn #{turn}, cost #{prev_cost} vs #{cost_so_far}" if @verbose
      @seen_prunes += 1
      return Float::INFINITY
    end
    @seen[turn][game.to_i] = cost_so_far

    legal = game.legal_spells
    # We got no moves so we lose.
    return Float::INFINITY if legal.empty?

    legal.map { |move, cost|
      game2 = game.dup
      winner = game2.cast_spell(move)
      @spells_cast += 1
      new_total = cost_so_far + cost

      case winner
      when :boss; Float::INFINITY
      when :me
        if new_total < @best_cost
          @best_cost = new_total
          @best_list = (spells_so_far + [move]).freeze
        end
        new_total
      else
        new_spells = spells_so_far + [move]
        best(game2, spells_so_far: new_spells, cost_so_far: new_total, turn: turn + 1)
      end
    }.min
  end

  def to_s
    "Pruned #@max_prunes max, #@seen_prunes seen, cast #@spells_cast spells\nSpells to cast: #@best_list"
  end
end

# This code is used to generate tables of max beatable boss HP.
# It is NOT USED when calculating the solution to day 22.
# (It is used when -b flag is passed).
def max_beatable(hard: true, verbose: true)
  # High-HP battles below the min_damage just took too long for my liking.
  # (Easy 2 damage: 304. Easy 3 damage: 300. Hard 1 damage: 270.)
  # On easy mode, you can beat any 1-damage boss:
  # Just cycle between recharge and drain.
  min_damage = hard ? 2 : 4
  max_hp = hard ? 157 : 299

  (min_damage..51).to_h { |damage|
    if damage <= 8
      # Silly shortcut: On low-damage battles, test the max first.
      # It works a lot of the time.
      g = Game.new(boss_hp: max_hp - 1, boss_damage: damage, hard: hard)
      if Search.new(g).best != Float::INFINITY
        puts "#{damage}: #{max_hp - 1}" if verbose
        next [damage, max_hp - 1]
      end
    end

    this_max = (4..max_hp).bsearch { |n|
      g = Game.new(boss_hp: n, boss_damage: damage, hard: hard)
      Search.new(g).best == Float::INFINITY
    }
    unless this_max
      puts "#{damage}: unknown" if verbose
      next [damage, nil]
    end

    max_hp = this_max
    # I format my results as "highest HP I'm able to beat".
    # The bsearch returns "lowest HP I can't beat", so we just subtract 1.
    puts "#{damage}: #{this_max - 1}" if verbose
    [damage, this_max - 1]
  }
end

if SEARCH_BOSS_HP
  puts max_beatable(hard: false)
  puts max_beatable(hard: true)
  Kernel.exit(0)
end

[false, true].each { |hard|
  s = Search.new(Game.new(hard: hard))
  puts s.best
  next unless VERBOSE
  p spells = s.best_list
  g = Game.new(hard: hard, verbose: true)
  spells.each { |s| g.cast_spell(s) }
}
