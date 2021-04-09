defmodule CoderRingTest do
  use CoderRing.TestCase
  alias CoderRing.MyCoderRing

  @ring :widget

  test "basic + reset + ring wrap" do
    assert :ok = MyCoderRing.reset(@ring)

    round1 = Enum.map(1..32, fn _ -> MyCoderRing.get_code(@ring) end)

    assert length(round1) == length(Enum.uniq(round1))

    round2 =
      Enum.map(1..32, fn _ ->
        "X" <> base = MyCoderRing.get_code(@ring)
        base
      end)

    assert Enum.sort(round1) == Enum.sort(round2)
  end

  test "new with atom" do
    %CoderRing{name: :ha} = CoderRing.new(:ha)
  end
end
