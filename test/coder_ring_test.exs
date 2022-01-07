defmodule CoderRingTest do
  use CoderRing.TestCase
  import Ecto.Query
  alias CoderRing.{Code, MyCoderRingProc, MySimpleCoderRing, Test.Repo}

  @ring :doodad

  setup_all do
    # Seed ring data.
    MySimpleCoderRing.populate_rings_if_empty()
  end

  test "basic + reset + ring wrap" do
    assert :ok = MySimpleCoderRing.reset(@ring)

    round1 = Enum.map(1..32, fn _ -> MySimpleCoderRing.get_code(@ring) end)

    assert length(round1) == length(Enum.uniq(round1))

    round2 =
      Enum.map(1..32, fn _ ->
        "X" <> base = MySimpleCoderRing.get_code(@ring)
        base
      end)

    assert Enum.sort(round1) == Enum.sort(round2)
  end

  test "bump: true" do
    c1 = MySimpleCoderRing.get_code(@ring)
    c2 = MySimpleCoderRing.get_code(@ring)
    c3 = MySimpleCoderRing.get_code(@ring, bump: true)

    assert byte_size(c1) == 1
    assert byte_size(c2) == 1
    assert byte_size(c3) == 2
  end

  test "MyCoderRingProc with caller_extra" do
    start_supervised!(MyCoderRingProc.child_spec(@ring))

    _ = Enum.map(1..16, fn _ -> MyCoderRingProc.get_code(@ring) end)

    fun = fn _ -> MyCoderRingProc.get_code(@ring, extra: "hi") end

    assert Enum.all?(
             Enum.map(1..32, fun),
             &(String.starts_with?(&1, "hi") and String.length(&1) == 3)
           )

    assert String.length(fun.(nil)) == 4
  end

  describe "Explitive filter" do
    @ring_str "widget"

    test "record count" do
      assert 1_048_557 == Repo.aggregate(from(Code, where: [name: @ring_str]), :count)
    end

    test "Skipped codes" do
      assert nil == Repo.one(from Code, where: [name: @ring_str, value: "SHIT"])
      assert %{value: "YA42"} = Repo.one(from Code, where: [name: @ring_str, value: "YA42"])
    end
  end
end
