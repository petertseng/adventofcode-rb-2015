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

# If any trait is negative and can't be saved
# (not even by putting all of the best ingredient for that trait),
# the cookie is doomed and will have a zero score.
def doomed_traits(trait_values, remaining, trait_bests)
  trait_values.select { |trait, value|
    value < 0 && -value >= remaining * trait_bests[trait]
  }
end

def cookie(ingredients, index, remaining, traits_so_far, trait_bests, results, amounts)
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

    doomed_traits = doomed_traits(traits_with, remaining - amount, trait_bests[index])

    unless doomed_traits.empty?
      if doomed_traits.any? { |k, _| ingredient[k] <= 0 }
        # Adding more of the ingredient dooms the cookie further.
        break
      else
        # Adding more of the ingredient helps a trait that is otherwise doomed.
        # We can calculate a minimum amount of this ingredient,
        # but I don't feel like writing that code.
        next
      end
    end

    amounts[index] = amount
    cookie(ingredients, index + 1, remaining - amount, traits_with, trait_bests, results, amounts)
  }
end

# Process ingredient with most-negative trait values first.
# That way we have the greatest chance of eliminating cookies in outer loops.
# That would reduce the amount of work we need to do.
ingredients = ingredients.sort_by { |_, v| v.values.min }
trait_bests = ingredients.each_index.map { |i|
  traits.to_h { |trait|
    [trait, ingredients.drop(i + 1).map { |_, ingred| ingred[trait] }.max]
  }
}
ingredients = ingredients.to_h

results = {best: [0, nil], best500: [0, nil]}
cookie(ingredients.values, 0, 100, traits.to_h { |t| [t, 0] }, trait_bests, results, ingredients.map { nil })

results.values_at(:best, :best500).each { |score, list|
  puts score
  puts ingredients.keys.zip(list).to_h if verbose
}
