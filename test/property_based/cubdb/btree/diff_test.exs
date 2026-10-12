defmodule PropertyBased.Btree.DiffTest do
  use ExUnit.Case
  use ExUnitProperties

  alias CubDB.Btree
  alias CubDB.Btree.Diff
  alias CubDB.Store

  require Btree

  import TestHelper

  @tag property_based: true
  property "Diff enumerates through updates from a btree to a more updated one" do
    entry =
      tuple({
        string(:utf8, max_length: 4),
        string(:utf8, max_length: 5)
      })

    check all(
            cap <- integer(2..32),
            entries <- list_of(entry, max_length: 30),
            updates <- list_of(entry, max_length: 10),
            max_runs: 50
          ) do
      {:ok, store} = Store.TestStore.create()
      from_btree = make_btree(store, entries, cap)

      to_btree =
        Enum.reduce(updates, from_btree, fn {key, val}, btree ->
          Btree.insert(btree, key, val)
        end)

      deletions =
        Enum.take_random(entries, div(length(entries), 3))
        |> Enum.map(fn {key, _} -> {key, Btree.deleted()} end)

      to_btree =
        Enum.reduce(deletions, to_btree, fn {key, _}, btree ->
          Btree.mark_deleted(btree, key)
        end)

      diff = Diff.new(from_btree, to_btree)

      expected_diff =
        updates
        |> Enum.map(fn {key, val} -> {key, Btree.value(val: val)} end)
        |> Enum.concat(deletions)
        |> Enum.reverse()
        |> Enum.uniq_by(&elem(&1, 0))
        |> List.keysort(0)

      assert Enum.to_list(diff) == expected_diff
    end
  end
end
