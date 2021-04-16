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
   the ring wraps around, the uniquizer will be incremented. Also, if
   `get_code/2` is called with the `bump: true`, then this will be
   incremented and the ring cycle reset.
3. The base code, coming directly from the seed data in the database.

## Setup

Include CoderRing as a dependency in your application:

```elixir
defp deps do
  [
    {:coder_ring, "~> 0.1.0"}
  ]
end
```

Configure code rings in your `config.exs` with something like:

```elixir
config :coder_ring, rings: [:widget, doodad: [base_length: 2]]
```

Here, we configured two code rings. Note that the `:rings` list may have
atoms for default options or keyword list-style entries (`{:doodad,
base_length: 2}`) if options are specified. See `CoderRing.new/1` for
available options.

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

Finally, create a CoderRing module in your application. The section below
explains the options.

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

## Creating a CoderRing Module for your Application

You'll want to create a module in your Application to expose the CoderRing
functionality. Here are your options.

### Stateless

This one is simplest, but it will require fetching current state from the database each time.

```elixir
defmodule MyApp.CoderRing do
  use CoderRing
end
```

### GenServer-based

You've chosen the BEAM for it's state-keeping prowess. In this option, a
long-running GenServer is spawned which will hold the current state, avoiding
the need to fetch state each time `get_code/2` is called. Look out, however,
if you're running with multiple servers as things will not work correctly if
each node is running its own GenServer.

See `CoderRing.GenRing` for details on setting up this method.

### Using a Global Process Registry

If your app is running on multiple nodes with Erlang clustering enabled,
another option is to spawn a GenServer under a global process registry, named
by the ring name, so that only one such process is allowed to run across the
cluster.

For more details on this method, see
[Global Registry Method](docs/global-registry-method.md).

## Dealing with an Unexpected Duplicate Code

If for some reason a code is returned which turns out not to be unique, it
probably has to do with a previously-used "extra" string being used after
switching to a different one in between. In this case, you may pass the
`bump: true` option into `get_code/2` to have the CoderRing begin using (or
incrementing) the uniquizer. In this case, the ring cycle is also reset, and
we should have another full cycle without conflicts.

## Dealing with Timeouts

While I didn't have trouble loading my local Postgres in development with 1
million+ code records during initial population, I did find that when doing
so on a deployment with the database over the network etc, I hit Ecto's
default 15-second timeout.

To solve this, you might need to increase the timeout. Try:

```elixir
CoderRing.populate_rings_if_empty(timeout: :timer.minutes(2))
```

## Filtering Bad Words

If you wish to ensure that the generated codes do not include any profane
words, also include [`expletive`](https://github.com/xavier/expletive) as a
dependency in your application:

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
