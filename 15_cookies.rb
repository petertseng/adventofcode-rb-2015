verbose = ARGV.delete('-v')

ingredients = ARGF.each_line.to_h { |line|
  name, traits = line.split(': ')
  # Parse capacity 2, durability 0 into {capacity: 2, durability: 0}, etc.
  [name, traits.split(', ').to_h { |x|
    a, b = x.split
    [a.to_sym, Integer(b)]
  }.freeze]
}.freeze
traits = ingredients.each_value.flat_map(&:keys).uniq.freeze
non_calorie_traits = (traits - [:calories]).freeze

best = 0
best_list = nil
best500 = 0
best500_list = nil

def trait_score(ingredient_amounts, trait)
  ingredient_amounts.sum { |ingredient, amount|
    ingredient[trait] * amount
  }
end

# This sucks because it only works for 4 ingredients.
(0..100).each { |x1|
  (0..(100 - x1)).each { |x2|
    (0..(100 - x1 - x2)).each { |x3|
      x4 = 100 - x1 - x2 - x3
      ingredient_amounts = ingredients.values.zip([x1, x2, x3, x4])
      score = non_calorie_traits.map { |trait|
        [trait_score(ingredient_amounts, trait), 0].max
      }.reduce(:*)
      calories = trait_score(ingredient_amounts, :calories)

      if score > best
        best = score
        best_list = [x1, x2, x3, x4]
      end
      if calories == 500 && score > best500
        best500 = score
        best500_list = [x1, x2, x3, x4]
      end
    }
  }
}

puts best
p ingredients.keys.zip(best_list).to_h if verbose
puts best500
p ingredients.keys.zip(best500_list).to_h if verbose
