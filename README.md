# CoderRing

Provides short, unique codes upon request.

## Methodology

The database is seeded with every possible base code. With the default of 4
characters, each being one of 32 possible characters, the database will be
populated with 1,048,576 possibilities (without the expletives filter). The
32 possible characters include `2-9` and `A-Z`, not including `I` or `O`.
This set was chosen to avoid ambiguity for human eyes.

When a code is requested with `get_code/2`, "max" is decremented by 1 from
the max used in finding the last code. (If it's the first code fetched, "max"
is the last record.) "r" is then a random number between 1 and "max",
inclusive. Records "r" and "max" are found in the table by their "position"
field. (Records positions are numbered from 1). The values for records "r"
and "max" are reversed, and the value landing out of bounds for future codes
in the "max" position is returned as the next code. This gives off the look
of truly random codes, but they never repeat.

Once the cycle completes, "max" is reset to the last record again and it
repeats. The records in the table will be randomized, but it doesn't really
matter since the records will again be pulled in random order.

## What is a Code?

A code generated by the system is comprised of three elements, concatenated
together:

1. The `:extra` option string supplied by the caller when invoking
   `get_code/2`.  If supplied, it should remain the same each call, or if it
   does change, it should not change to a previously-used value. An example use
   case is the year as 2 digits. For most use cases, this piece can be ignored.
2. A "uniquizer" string managed by CoderRing. If the number of codes
   generated in the seed is not exhausted, this will be an empty string. When
   the ring wraps around, a character or so may be used here. Also, if
   `get_code/2` is called with the `bump: true`, then this will be incremented
   and the ring cycle reset.
3. The base code, coming directly from the seed data in the database.

## Setup

Include CoderRing as a dependency in your application:

```elixir
defp deps do
  [
    {:coder_ring,
      git: "git@github.com:instinctscience/coder_ring.git",
      branch: "main"},
  ]
end
```

Configure code rings in your `config.exs` with something like:

```elixir
config :coder_ring, rings: [:widget, doodad: [base_length: 2]]
```

Here, we configured two code rings. Note that the `:rings` list may have
atoms for default options or keyword list-style entries (`{:doodad,
base_length: 2}`) if options are specified.

Next, add the following to `change/0` in a new or existing Ecto migration:

```elixir
def change do
  CoderRing.Migration.change()
end
```

Make sure the database tables are seeded somewhere before use, whether in
your existing `seeds.exs` or other application code:

```elixir
CoderRing.populate_rings_if_empty()
```

Finally, create a module like this in your application:

```elixir
defmodule MyApp.CoderRing do
  use CoderRing
end
```

Now you can use `MyApp.CoderRing.get_code/2` to generate new codes.

```elixir
iex> MyApp.CoderRing.get_code(:widget)
"7GRY"
iex> MyApp.CoderRing.get_code(:widget)
"PJ83"
iex> MyApp.CoderRing.get_code(:widget)
"NNW3"
iex> MyApp.CoderRing.get_code(:widget)
"Q5QA"
```

Bonus feature: If for some reason a code is returned which turns out not to
be unique, it probably has to do with a previously-used "extra" string being
used after switching to a different one in between. In this case, you may
pass the `bump: true` option into `get_code/2` to have the CoderRing begin
using (or incrementing) the uniquizer. In this case, the ring cycle is also
reset, and we should have another full cycle without conflicts.

## Filtering Bad Words

If you wish to ensure that the generated codes do not include any profane
words, also include the following dependency in your application:

```elixir
{:expletive, "~> 0.1.0"},
```

And then add the `:expletive_blacklist` option in the pertinent ring config:

```elixir
config :coder_ring, rings: [widget: [expletive_blacklist: :english]]
```

## Acknowledgements

The methodology is appreciatively derived from Robert Gamble's accepted
answer on [this Stack Overflow
page](https://stackoverflow.com/questions/196017/unique-non-repeating-random-numbers-in-o1/16097246#16097246).
