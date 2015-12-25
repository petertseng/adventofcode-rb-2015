verbose = ARGV.delete('-v')

HERO = { hp: 100.0 }.freeze
nums = if ARGV.size >= 3 && ARGV.all? { |arg| arg.match?(/^\d+$/) }
  ARGV
else
  ARGF.read.scan(/\d+/)
end

BOSS = {
  hp: Float(nums[0]),
  damage: Integer(nums[1]),
  armor: Integer(nums[2]),
}.freeze

WEAPONS = [
  { cost:  8, damage: 4 },
  { cost: 10, damage: 5 },
  { cost: 25, damage: 6 },
  { cost: 40, damage: 7 },
  { cost: 74, damage: 8 },
]

ARMORS = [
  { cost:   0 },
  { cost:  13, armor: 1 },
  { cost:  31, armor: 2 },
  { cost:  53, armor: 3 },
  { cost:  75, armor: 4 },
  { cost: 102, armor: 5 },
]

RINGS = [
  { cost:   0 },
  { cost:  25, damage: 1 },
  { cost:  50, damage: 2 },
  { cost: 100, damage: 3 },
  { cost:  20, armor:  1 },
  { cost:  40, armor:  2 },
  { cost:  80, armor:  3 },
]

module Rpg
  # Oh this is super questionable that this goes on a Hash, but:
  # 1) that's why it's in a refinement, and
  # 2) it makes `hero.turns_to_kill(BOSS)` look very natural.
  refine Hash do
    def turns_to_kill(defender)
      (defender[:hp] / [1, self[:damage] - defender[:armor]].max).ceil
    end
  end

  refine Array do
    def sum_by(key)
      sum { |x| x[key] || 0 }
    end
  end
end

using Rpg

WEAPONS.product(ARMORS, RINGS, RINGS).each_with_object(
  min: {cost: Float::INFINITY, equipment: [], accept: :<.to_proc},
  max: {cost: 0, equipment: [], accept: :>.to_proc}
) { |equipment, answer|
  _, _, ring1, ring2 = equipment
  # Can't duplicate rings.
  next if ring1 == ring2 && ring1[:cost] != 0

  hero = HERO.merge(
    damage: equipment.sum_by(:damage),
    armor: equipment.sum_by(:armor),
  )
  cost = equipment.sum_by(:cost)
  # If we win (we kill in fewer turns), record min. If lose, record max.
  sym = hero.turns_to_kill(BOSS) <= BOSS.turns_to_kill(hero) ? :min : :max
  ans = answer[sym]
  if ans[:accept][cost, ans[:cost]]
    ans[:cost] = cost
    ans[:equipment] = equipment
  end
}.values_at(:min, :max).each { |v| puts v[:cost]; puts v[:equipment] if verbose }
