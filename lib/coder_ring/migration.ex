defmodule CoderRing.Migration do
  @moduledoc """
  Handles table migrations.

  Invoke `CoderRing.Migration.change/0` in your migration's `change/0`
  function.
  """
  use Ecto.Migration

  @spec change :: :ok
  def change do
    create table(:code_memos, primary_key: false) do
      add(:name, :string, primary_key: true)
      add(:extra_num, :integer, null: false, default: 0)
      add(:caller_extra, :string, null: false, default: "")
      add(:last_max_pos, :integer)
    end

    create table(:codes) do
      add(:position, :integer, null: false)
      add(:name, references(:code_memos, type: :string, column: :name), null: false)
      add(:value, :string, null: false)
    end

    :ok
  end
end
