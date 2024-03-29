# Advent of Code

These are my solutions to http://adventofcode.com

All solutions are written in Ruby.

[![Build Status](https://travis-ci.org/petertseng/adventofcode-rb-2015.svg?branch=master)](https://travis-ci.org/petertseng/adventofcode-rb-2015)

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

* 6 (Light grid): The naive approach would be to create a 1000x1000 array of lights and iterate over that. Various approaches are able to instead operate on the rectangles listed in the instructions. I used a sweep line approach.
* 11 (Passwords): Really bends over backwards to skip generating passwords that can be known in advance to be invalid. Questionable tradeoff of code size for time.
* 17 (Container Combinations): Dynamic programming to count the number of subsets is quite faster than enumerating every possible combination.
* 20 (Factors): Recursion on the sum of divisors formula.
* 22 (Wizard): Tree search with pruning of already-beaten branches and already-seen states.
* 24 (Partition): Most solutions cut corners: As soon as they find a subset that sums to `total / num_groups` they stop and don't check that the remaining packages can be balanced.
  This happens to work because it so happens that for the lowest QE subset, the other packages can in fact be balanced.
  In fact, for my input, every grouping of lowest cardinality resulted in being able to balance the remaining packages.
  However, a complete solution should check for partitionability of the remaining packages, and ways to do so efficiently are quite fascinating (read the papers mentioned in the header of `ckk.rb`).
  I decided implementing Complete Karmarkar-Karp was sufficient, and didn't even get into Sequential Number Partitioning or Recursive Number Partitioning.
  Due to only running CKK on reasonable candidates, the additional correctness check had no noticeable impact on runtime.

## Ruby version compatibility

Hello from the future!
Even though Ruby 2.2 was the current Ruby version at the time of the event, this repository uses Ruby 2.4 because I like to keep things up to date.
I have no qualms about rewriting Git history either.

No attempt will be made to maintain compatibility with any earier Ruby versions.

## On Refinements

My use of these is probably a bit gratuitous.
But I must say I really like the idea of having lexically-scoped monkey-patches.
