defmodule CoderRing.Code do
  @moduledoc """
  Schema for a code, pending use.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias __MODULE__

  @primary_key {:position, :integer, []}
  schema "codes" do
    field :name, :string
    field :value, :string
  end

  @typedoc """
  * `:position` - Primary key and auto-incrementing integer.
  * `:name` - Name of the code type.
  * `:value` - A pre-generated code.
  """
  @type t :: %Code{
          position: non_neg_integer,
          name: String.t(),
          value: String.t()
        }

  @doc "Changeset for creating a new code."
  @spec changeset(t | Changeset.t(), map) :: Changeset.t()
  def changeset(code_or_changeset, params) do
    code_or_changeset
    |> update_changeset(params)
  end

  @doc "Changeset for updating an existing code."
  @spec update_changeset(t | Changeset.t(), map) :: Changeset.t()
  def update_changeset(code_or_changeset, params \\ %{}) do
    required = [:name, :value]

    code_or_changeset
    |> cast(params, required)
    |> validate_required(required)
  end
end
