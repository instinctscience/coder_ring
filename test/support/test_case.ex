defmodule CoderRing.TestCase do
  @moduledoc "Test case, setting up a shared sandbox."
  use ExUnit.CaseTemplate
  alias CoderRing.Test.Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
    Sandbox.mode(Repo, {:shared, self()})

    :ok
  end
end
