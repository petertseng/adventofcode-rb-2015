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

def cookie(ingredients, index, remaining, traits_so_far, results, amounts)
  ingredient = ingredients[index]

  if index == ingredients.size - 1
    calories = traits_so_far.delete(:calories) + remaining * ingredient[:calories]
    score = traits_so_far.reduce(1) { |acc, (trait, v)|
      acc * [remaining * ingredient[trait] + v, 0].max
    }

    amounts[index] = remaining
    results[:best] = [score, amounts.dup] if score > results[:best][0]
    results[:best500] = [score, amounts.dup] if calories == 500 && score > results[:best500][0]
    return
  end

  (0..remaining).each { |amount|
    traits_with = traits_so_far.merge(ingredient) { |_, v1, v2|
      v1 + amount * v2
    }
    amounts[index] = amount
    cookie(ingredients, index + 1, remaining - amount, traits_with, results, amounts)
  }
end

results = {best: [0, nil], best500: [0, nil]}
cookie(ingredients.values, 0, 100, traits.to_h { |t| [t, 0] }, results, ingredients.map { nil })

results.values_at(:best, :best500).each { |score, list|
  puts score
  puts ingredients.keys.zip(list).to_h if verbose
}
