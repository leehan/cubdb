defmodule PropertyBased.Btree.KeyRangeTest do
  use ExUnit.Case
  use ExUnitProperties

  alias CubDB.Btree.KeyRange
  alias CubDB.Store

  import TestHelper

  @tag property_based: true
  property "a KeyRange enumerates through a range of keys" do
    check all(
            cap <- integer(2..32),
            key_values <-
              list_of(
                tuple({
                  string(:utf8, max_length: 8),
                  string(:utf8, max_length: 10)
                }),
                max_length: 100
              ),
            min <- string(:utf8, max_length: 8),
            max <- string(:utf8, max_length: 8),
            min_included <- boolean(),
            max_included <- boolean(),
            max_runs: 50
          ) do
      {:ok, store} = Store.TestStore.create()
      btree = make_btree(store, key_values, cap)
      min_key = {min, min_included}
      max_key = {max, max_included}
      key_range = KeyRange.new(btree, min_key, max_key)
      reverse_key_range = KeyRange.new(btree, min_key, max_key, true)

      expected_key_values =
        key_values
        |> Enum.reverse()
        |> Enum.uniq_by(&elem(&1, 0))
        |> Enum.filter(fn {key, _} ->
          ((min_included && key >= min) || key > min) &&
            ((max_included && key <= max) || key < max)
        end)
        |> List.keysort(0)

      assert Enum.to_list(key_range) == expected_key_values
      assert Enum.to_list(reverse_key_range) == expected_key_values |> Enum.reverse()
    end
  end
end
