defmodule CoderRingTest do
  use CoderRing.TestCase
  alias CoderRing.{MyCoderRingProc, MyStatelessCoderRing}

  @ring :widget

  test "basic + reset + ring wrap" do
    assert :ok = MyStatelessCoderRing.reset(@ring)

    round1 = Enum.map(1..32, fn _ -> MyStatelessCoderRing.get_code(@ring) end)

    assert length(round1) == length(Enum.uniq(round1))

    round2 =
      Enum.map(1..32, fn _ ->
        "X" <> base = MyStatelessCoderRing.get_code(@ring)
        base
      end)

    assert Enum.sort(round1) == Enum.sort(round2)
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

  test "new with atom" do
    %CoderRing{name: :ha} = CoderRing.new(:ha)
  end
end
