defmodule PropertyBased.CubDb.Store.File.BlocksTest do
  use ExUnit.Case
  use ExUnitProperties

  alias CubDB.Store.File.Blocks

  @tag property_based: true
  property "adding and removing block headers" do
    check all(
            block_size <- integer(4..32),
            bin <- string(:ascii, min_length: 1, max_length: 64),
            loc <- integer(0..256),
            max_runs: 100
          ) do
      bin_with_headers = Blocks.add_markers(bin, loc, block_size) |> Enum.join()

      assert Blocks.length_with_markers(loc, byte_size(bin), block_size) ==
               byte_size(bin_with_headers)

      assert Blocks.strip_markers(bin_with_headers, loc, block_size) |> Enum.join() ==
               bin
    end
  end
end
