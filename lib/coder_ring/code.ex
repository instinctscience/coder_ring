defmodule CoderRing.Code do
  @moduledoc """
  Schema for a code, pending use.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias __MODULE__

  schema "codes" do
    field :name, :string
    field :position, :integer
    field :value, :string
  end

  @typedoc """
  * `:id` - Unique integer ID for the code.
  * `:name` - Name of the code type.
  * `:position` - Primary key and auto-incrementing integer.
  * `:value` - A pre-generated code.
  """
  @type t :: %Code{
          id: non_neg_integer,
          name: String.t(),
          position: non_neg_integer,
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
