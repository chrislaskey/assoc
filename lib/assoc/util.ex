defmodule Assoc.Util do
  @moduledoc """
  Collection of utility functions
  """

  @doc """
  Recursively converts the keys of a map into an atom.

  Options:

    `:whitelist` -> List of strings to convert to atoms. When passed, only strings in whitelist will be converted.

  Example:

    keys_to_atoms(%{"nested" => %{"example" => "value"}})

  Returns:

    %{nested: %{example: "value"}}
  """
  def keys_to_atoms(map, options \\ [])
  def keys_to_atoms(%_{} = struct, _), do: struct

  def keys_to_atoms(map, options) when is_map(map) do
    for {key, value} <- map, into: %{} do
      key =
        case is_bitstring(key) do
          false ->
            key

          true ->
            case Keyword.get(options, :whitelist) do
              nil ->
                String.to_atom(key)

              whitelist ->
                case Enum.member?(whitelist, key) do
                  false -> key
                  true -> String.to_atom(key)
                end
            end
        end

      {key, keys_to_atoms(value, options)}
    end
  end

  def keys_to_atoms(value, _), do: value
end
