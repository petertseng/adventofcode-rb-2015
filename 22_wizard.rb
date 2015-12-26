EXAMPLES = ARGV.delete('-d')
VERBOSE = ARGV.delete('-v')

nums = if ARGV.size >= 2 && ARGV.all? { |arg| arg.match?(/^\d+$/) }
  ARGV
else
  ARGF.read.scan(/\d+/)
end

BOSS_HP = Integer(nums[0])
BOSS_DAMAGE = Integer(nums[1])

class Game
  COSTS = {
    magic_missile: 53,
    drain: 73,
    shield: 113,
    poison: 173,
    recharge: 229,
  }

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
  end

  def to_i
    # my MP, 6 my HP, 6 boss HP, 3 shield, 3 poison, 3 recharge
    # (My MP is potentially unbounded, but Recharge-only battles are losses)
    timers = @shield_time << 6 | @poison_time << 3 | @recharge_time
    @my_mp << 21 | @my_hp << 15 | @boss_hp << 9 | timers
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
    # Prune: we've seen a better one already.
    # This is about a 2x speedup (0.45 seconds -> 0.2 seconds)
    if cost_so_far > @best_cost
      puts "Best so far is #@best_cost, pruning a #{cost_so_far}" if @verbose
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

[false, true].each { |hard|
  s = Search.new(Game.new(hard: hard))
  puts s.best
  next unless VERBOSE
  p spells = s.best_list
  g = Game.new(hard: hard, verbose: true)
  spells.each { |s| g.cast_spell(s) }
}
