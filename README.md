# Advent of Code

These are my solutions to http://adventofcode.com

All solutions are written in Ruby.

## Input

In general, all solutions can be invoked in both of the following ways:

* Without command-line arguments, takes input on standard input.
* With command-line arguments, reads input from the named files (- indicates standard input).

Some may additionally support other ways:

* 4 (Advent Coins): Pass the secret key in ARGV.
* 10 (Look and Say): Pass the seed sequence in ARGV.
* 11 (Passwords): Pass the initial password in ARGV.
* 20 (Factors): Pass the target number of gifts in ARGV.
* 21 (RPG): Pass the Boss's HP, damage, and armor in ARGV, in that order.
* 22 (Wizard): Pass the Boss's HP and damage in ARGV, in that order. Pass `-d` flag to see example battles.
* 25 (Triangular): Pass the row and column number in ARGV, in that order.

## Highlights

In general, I am most interested in those problems where a thoughtfully-selected algorithm leads itself to great speed improvements over a naive solution.
Problems that I thought fit this criterion:

* 11 (Passwords): Really bends over backwards to skip generating passwords that can be known in advance to be invalid. Questionable tradeoff of code size for time.
* 17 (Container Combinations): Dynamic programming to count the number of subsets is quite faster than enumerating every possible combination.
* 22 (Wizard): Tree search with pruning of already-beaten branches and already-seen states. Could probably be improved a bit more by prioritising the higher-value spells (Poison when possible), but it is already fast enough.
* 24 (Partition): Most solutions cut corners: As soon as they find a subset that sums to `total / num_groups` they stop and don't check that the remaining packages can be balanced.
  This happens to work because it so happens that for the lowest QE subset, the other packages can in fact be balanced.
  In fact, for my input, every grouping of lowest cardinality resulted in being able to balance the remaining packages.
  However, a complete solution should check for partitionability of the remaining packages, and ways to do so efficiently are quite fascinating (read the papers mentioned in the header of `ckk.rb`).
  I decided implementing Complete Karmarkar-Karp was sufficient, and didn't even get into Sequential Number Partitioning or Recursive Number Partitioning.
  CKK only slowed down the solution from 0.7 seconds to 1.0 seconds:
  A small price to pay in exchange for ensuring that the solution is correct.

## On Refinements

My use of these is probably a bit gratuitous.
But I must say I really like the idea of having lexically-scoped monkey-patches.
