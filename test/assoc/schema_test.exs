defmodule Assoc.SchemaTest do
  use ExUnit.Case
  use Assoc.DataCase

  import Assoc.Test.Factories

  alias Assoc.Test.User

  doctest Assoc.Schema

  describe "preload_all" do
    setup do
      user = insert_user!()

      {:ok, user: user}
    end

    test "loads all associations, including `through:` associations", %{user: user} do
      %Ecto.Association.NotLoaded{} = user.addresses
      %Ecto.Association.NotLoaded{} = user.roles
      %Ecto.Association.NotLoaded{} = user.tags
      %Ecto.Association.NotLoaded{} = user.user_roles

      user = User.preload_all(user)

      assert is_list(user.addresses)
      assert is_list(user.roles)
      assert is_list(user.tags)
      assert is_list(user.user_roles)
    end
  end
end
