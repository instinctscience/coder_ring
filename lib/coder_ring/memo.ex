defmodule CoderRing.Memo do
  @moduledoc """
  Schema for a coder ring state.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias __MODULE__

  @primary_key {:name, :string, []}
  schema "code_memos" do
    field :caller_extra, :string, default: ""
    field :extra_num, :integer, default: 0
    field :last_max_pos, :integer
  end

  @typedoc """
  * `:name` - Name of the code type. (eg. "rx")
  * `:caller_extra` - Additional prefix last used by the caller.
    If we get a new one, `:extra` is emptied and the ring is reset.
  * `:extra_num` - A number to be passed to `integer_to_string/1` for an extra
    value to be used between `:caller_extra` and the base code.
  * `:last_max_pos` - Position of the code record last used as "max".
    Value is `nil` before the first iteration is made.
  """
  @type t :: %Memo{
          name: String.t(),
          caller_extra: String.t(),
          extra_num: non_neg_integer,
          last_max_pos: non_neg_integer | nil
        }

  @doc "Create a new Memo struct."
  @spec new(keyword) :: t
  def new(args \\ []) do
    struct(Memo, args)
  end

  @doc "Changeset for creating a new memo."
  @spec changeset(t | Changeset.t(), map) :: Changeset.t()
  def changeset(memo_or_changeset, params) do
    required = [:name]

    memo_or_changeset
    |> cast(params, required)
    |> validate_required(required)
    |> update_changeset(params)
  end

  @doc "Changeset for updating an existing memo."
  @spec update_changeset(t | Changeset.t(), map) :: Changeset.t()
  def update_changeset(memo_or_changeset, params \\ %{}) do
    optional = [:caller_extra, :extra_num, :last_max_pos]

    memo_or_changeset
    |> cast(params, optional)
  end
end
