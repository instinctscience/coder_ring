defmodule CoderRing do
  @moduledoc File.read!("README.md")
  import Ecto.Query
  alias CoderRing.{Code, Memo}
  alias Ecto.Changeset
  require Logger

  # 32 (readable) chars for codes: 2-9, A-Z (minus I and O)
  @chars ~w(V S E 2 9 3 A H 7 Q 6 R 4 B T 5 C L X G J Z F P D W U K Y M 8 N)

  @default_base_length 4

  @doc "Invoke the `name` ring with the given `message`."
  @callback call(name :: atom, message :: any) :: any

  defstruct base_length: @default_base_length, blacklist: nil, memo: nil, name: nil, repo: nil

  @typedoc """
  * `:base_length` - Number of characters to use in the base code.
  * `:blacklist` - Set this to `:english` to use the `Expletive` package's
    English word blacklist. Codes with occurrences of these words will be
    skipped in the database seeding step.
  * `:memo` - State-variable data, synced to the "code_memos" table.
  * `:name` - Name of this coder ring: .
  * `:repo` - Ecto.Repo module to use.
  """
  @type t :: %CoderRing{
          base_length: non_neg_integer,
          blacklist: atom,
          memo: Memo.t() | nil,
          name: atom,
          repo: module
        }

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def call(name, message) do
        # Lame logic where memo is fetched & dropped every time.
        # Deserves to be overridden.
        {reply, _state} =
          name
          |> CoderRing.ring()
          |> CoderRing.load_memo()
          |> CoderRing.invoke(message)

        reply
      end

      @doc """
      Get the next code in the ring.

      ## Options

      * `:bump` - If `true`, the uniquizer will be incremented and the ring
        cycle reset. This should be used during a retry if a duplicate code
        returned. (This should only happen if a previously-used "extra"
        string is used after switching to a different one in between.)
      """
      @spec get_code(atom, keyword) :: String.t()
      def get_code(name, opts \\ []), do: call(name, {:get_code, opts})

      @doc "Reset the ring from the beginning."
      @spec reset(atom) :: :ok
      def reset(name), do: call(name, :reset)

      defoverridable call: 2
    end
  end

  @doc "Make a new ring struct."
  @spec new(atom | keyword | {atom, keyword}) :: t
  def new(name) when is_atom(name), do: new(name: name)
  def new({name, opts}), do: opts |> Keyword.put(:name, name) |> new()

  def new(opts) do
    name = opts[:name] || raise ":name option is required."
    is_atom(name) || raise ":name must be an atom."
    base_length = opts[:base_length] || @default_base_length
    base_length in 1..4 || raise "Only :base_length 1 and 4 are supported."
    repo = opts[:repo] || Application.get_env(:coder_ring, :repo)
    bl = opts[:expletive_blacklist]
    bl in [nil, :english, :international] || raise "Invalid expletive_blacklist: #{inspect(bl)}"

    %CoderRing{
      base_length: base_length,
      blacklist: bl,
      memo: nil,
      name: name,
      repo: repo
    }
  end

  @doc "List all configured rings. (Memos will be unloaded, nil.)"
  @spec rings :: [t]
  def rings, do: Enum.map(Application.get_env(:coder_ring, :rings), &new/1)

  @doc "Get a ring by its name."
  @spec ring(atom) :: t | nil
  def ring(name), do: Enum.find(rings(), &(&1.name == name))

  @doc "Invoke the functionality identified by `message`. Memo should be loaded."
  @spec invoke(t, message :: any) :: {reply :: any, t}
  def invoke(ring, :reset) do
    {:ok, do_reset(ring)}
  end

  def invoke(%{memo: memo, name: name, repo: repo} = ring, {:get_code, opts}) do
    bump = opts[:bump] || false
    extra = opts[:extra] || ""

    memo_cs =
      if extra != memo.extra do
        # Caller has new extra string. Start ring over so we have a fresh set.
        reset_memo_change(memo)
      else
        if bump do
          Logger.warn("CoderRing: Bumping uniquizer")
          reset_memo_change(memo, memo.uniquizer_num + 1)
        else
          Memo.changeset(memo, %{})
        end
      end

    {:ok, {base, max_pos, uniquizer_num}} =
      repo.transaction(fn ->
        {max, uniquizer_num} = get_max(%{ring | memo: Changeset.apply_changes(memo_cs)})

        r_pos = Enum.random(1..max.position)

        r = repo.one!(from Code, where: [name: ^to_string(name), position: ^r_pos])

        r |> Code.changeset(%{value: max.value}) |> repo.update!()
        max |> Code.changeset(%{value: r.value}) |> repo.update!()

        {r.value, max.position, uniquizer_num}
      end)

    uniquizer = if uniquizer_num == 0, do: "", else: integer_to_string(uniquizer_num - 1)

    code = "#{extra}#{uniquizer}#{base}"

    args = %{extra: extra, uniquizer_num: uniquizer_num, last_max_pos: max_pos}
    memo = memo_cs |> Memo.changeset(args) |> repo.update!()

    {code, %{ring | memo: memo}}
  end

  # Get the next code to be used as "max" and a possibly updated uniquizer_num.
  @spec get_max(t) :: {Code.t(), non_neg_integer}
  defp get_max(%{memo: %{uniquizer_num: un, last_max_pos: last_max_pos}, name: name} = ring) do
    {max_pos, un} =
      cond do
        last_max_pos == nil -> {code_count(ring), un}
        last_max_pos == 1 -> {code_count(ring), un + 1}
        true -> {last_max_pos - 1, un}
      end

    {ring.repo.one!(from Code, where: [name: ^to_string(name), position: ^max_pos]), un}
  end

  # Convert a integer to a string, with character set matching @chars.
  @spec integer_to_string(non_neg_integer) :: String.t()
  defp integer_to_string(int) do
    int
    |> Integer.to_string(32)
    |> String.replace(~w(0 1 I O), fn
      "0" -> "X"
      "1" -> "W"
      "I" -> "Y"
      "O" -> "Z"
    end)
  end

  # Get the total number of codes in the ring.
  @spec code_count(t) :: non_neg_integer
  defp code_count(%{base_length: base_len}) do
    round(:math.pow(length(@chars), base_len))
  end

  # Reset the ring cycle.
  @spec do_reset(t) :: t
  defp do_reset(%{memo: memo, repo: repo} = ring) do
    %{ring | memo: memo |> reset_memo_change() |> repo.update!()}
  end

  # Create a changeset on `memo`, resetting the ring cycle.
  @spec reset_memo_change(Memo.t()) :: Changeset.t()
  defp reset_memo_change(memo, uniquizer_num \\ 0) do
    Memo.changeset(memo, %{uniquizer_num: uniquizer_num, last_max_pos: nil})
  end

  @doc "Load the ring into the database if it isn't already there."
  @spec populate_if_empty(t) :: t
  def populate_if_empty(%{memo: nil} = ring), do: populate(ring)
  def populate_if_empty(ring), do: ring

  @doc "Get the memo from db for the given ring `name`."
  @spec get_memo(t) :: Memo.t() | nil
  def get_memo(%{name: name, repo: repo}) do
    repo.one(from Memo, where: [name: ^to_string(name)])
  end

  @doc "Load the relevant memo from the database into `ring`."
  @spec load_memo(t) :: t
  def load_memo(ring), do: %{ring | memo: get_memo(ring)}

  @doc "Load the ring into the database."
  @spec populate(t) :: t
  def populate(%{blacklist: bl, name: name, repo: repo} = ring) do
    expletive_config = bl && Expletive.configure(blacklist: apply(Expletive.Blacklist, bl, []))

    # Comile code record data for speedy, single-query insert.
    {values, next_pos} =
      Enum.reduce(all_codes(ring), {[], 1}, fn val, {acc_list, acc_pos} ->
        if expletive_config && Expletive.profane?(val, expletive_config),
          do: {acc_list, acc_pos},
          else: {["('#{name}', #{acc_pos}, '#{val}')" | acc_list], acc_pos + 1}
      end)

    {:ok, memo} =
      repo.transaction(fn ->
        Logger.warn("Coder ring (#{name}) loading #{next_pos - 1} codes...")

        memo = repo.insert!(Memo.new(name: to_string(name)))

        str = Enum.join(values, ",")
        repo.query!("INSERT INTO codes (name, position, value) VALUES #{str}")

        Logger.warn("Coder ring (#{name}) is ready.")

        memo
      end)

    %{ring | memo: memo}
  end

  @doc "For each ring, seed its data if it hasn't already been done."
  @spec populate_rings_if_empty :: :ok
  def populate_rings_if_empty do
    Enum.each(rings(), &populate_if_empty/1)
  end

  # Build the full list of all possible codes.
  @spec all_codes(t) :: [String.t()]
  defp all_codes(%{base_length: 4}) do
    for a <- @chars, b <- @chars, c <- @chars, d <- @chars do
      Enum.join([a, b, c, d])
    end
  end

  defp all_codes(%{base_length: 3}) do
    for a <- @chars, b <- @chars, c <- @chars do
      Enum.join([a, b, c])
    end
  end

  defp all_codes(%{base_length: 2}) do
    for a <- @chars, b <- @chars do
      Enum.join([a, b])
    end
  end

  defp all_codes(%{base_length: 1}) do
    for a <- @chars, do: a
  end
end
