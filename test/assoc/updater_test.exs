defmodule Assoc.UpdaterTest do
  use ExUnit.Case
  use Assoc.DataCase

  import Assoc.Test.Factories

  alias Assoc.Test.Address
  alias Assoc.Test.Tag
  alias Assoc.Test.User

  doctest Assoc.Updater

  # Subject

  defmodule Subject do
    use Assoc.Updater, repo: Assoc.Test.Repo

    def call(parent, params), do: update_associations(parent, params)
  end

  # Helpers

  defp get_ids(record, key) do
    record
    |> reload([key])
    |> Map.get(key)
    |> Enum.map(& &1.id)
  end

  defp reload(record, associations) do
    Repo.preload(record, associations, force: true)
  end

  # Tests

  describe "implementations" do
    setup do
      tag = insert_tag!()
      user = insert_user!()
      user = reload(user, [:tags])

      assert length(user.tags) == 0

      params = %{
        tags: [tag]
      }

      {:ok, params: params, user: user}
    end

    test "direct function call", %{params: params, user: user} do
      {:ok, user} = Assoc.Updater.update_associations(Assoc.Test.Repo, user, params)
      user = reload(user, [:tags])

      assert length(user.tags) == 1
    end

    test "macro in a module with `use`", %{params: params, user: user} do
      {:ok, user} = Subject.call(user, params)
      user = reload(user, [:tags])

      assert length(user.tags) == 1
    end
  end

  describe "general behaviour" do
    test "keeps current associations if association key is not passed" do
      address = insert_address!()
      tag = insert_tag!()

      user = insert_user!()
      user = reload(user, [:addresses, :tags])

      assert length(user.addresses) == 0
      assert length(user.tags) == 0

      # Create

      params = %{
        addresses: [address],
        tags: [tag]
      }

      {:ok, user} = Subject.call(user, params)
      user = reload(user, [:addresses, :tags])

      assert length(user.addresses) == 1
      assert length(user.tags) == 1

      # Update

      params = %{
        addresses: []
      }

      {:ok, user} = Subject.call(user, params)
      user = reload(user, [:addresses, :tags])

      assert length(user.addresses) == 0
      assert length(user.tags) == 1
    end

    test "can update association values" do
      tag_constant = insert_tag!()
      tag_updated = insert_tag!()

      user = insert_user!()
      user = reload(user, [:tags])

      assert length(user.tags) == 0

      # Create Association and Optionally Update Association Attributes

      params = %{
        tags: [
          %{id: tag_constant.id},
          %{id: tag_updated.id, name: "New Name"}
        ]
      }

      {:ok, user} = Subject.call(user, params)
      tag_constant = Repo.get(Tag, tag_constant.id)
      tag_updated = Repo.get(Tag, tag_updated.id)
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 2
      assert tag_constant.id in tag_ids
      assert tag_constant.name == tag_constant.name
      assert tag_updated.id in tag_ids
      assert tag_updated.name == "New Name"
    end

    test "overwrites current associations if key is passed" do
      tag1 = insert_tag!()
      tag2 = insert_tag!()
      tag3 = insert_tag!()

      user = insert_user!()
      user = reload(user, [:tags])

      assert length(user.tags) == 0

      # Create

      params = %{
        tags: [tag1, tag2]
      }

      {:ok, user} = Subject.call(user, params)
      user = reload(user, [:tags])
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 2
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
      assert tag3.id not in tag_ids

      # Update

      params = %{
        tags: [tag3]
      }

      {:ok, user} = Subject.call(user, params)
      user = reload(user, [:tags])
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 1
      assert tag1.id not in tag_ids
      assert tag2.id not in tag_ids
      assert tag3.id in tag_ids
    end

    test "supports both structs and maps for association params" do
      tag1 = insert_tag!()
      tag2 = insert_tag!()
      tag3 = insert_tag!()

      user = insert_user!()
      user = reload(user, [:tags])

      assert length(user.tags) == 0

      # Create: Using Structs

      params = %{
        tags: [
          tag1,
          tag2
        ]
      }

      {:ok, user} = Subject.call(user, params)
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 2
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
      assert tag3.id not in tag_ids

      # Update: Using Maps

      params = %{
        tags: [
          %{id: tag1.id},
          %{id: tag3.id}
        ]
      }

      {:ok, user} = Subject.call(user, params)
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 2
      assert tag1.id in tag_ids
      assert tag2.id not in tag_ids
      assert tag3.id in tag_ids

      # Update: Using Mix of Structs and Maps

      params = %{
        tags: [
          %{id: tag1.id},
          tag2
        ]
      }

      {:ok, user} = Subject.call(user, params)
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 2
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
      assert tag3.id not in tag_ids
    end
  end

  describe "association type: belongs_to" do
    setup do
      address = reload(insert_address!(), [:user])
      user = reload(insert_user!(), [:addresses])

      {:ok, address: address, user: user}
    end

    test "update using map", %{address: address, user: user} do
      assert length(user.addresses) == 0
      assert is_nil(address.user)

      # Update

      params = %{
        user: %{
          id: user.id,
          name: "updated name"
        }
      }

      {:ok, address} = Subject.call(address, params)
      address = reload(address, [:user])
      address_ids = get_ids(user, :addresses)

      assert not is_nil(address.user)
      assert address.user.id == user.id
      assert address.user.name == "updated name"
      assert address.id in address_ids
    end

    test "update and delete using struct", %{address: address, user: user} do
      assert length(user.addresses) == 0
      assert is_nil(address.user)

      # Update

      params = %{user: user}

      {:ok, address} = Subject.call(address, params)
      address = reload(address, [:user])
      address_ids = get_ids(user, :addresses)

      assert not is_nil(address.user)
      assert address.user.id == user.id
      assert address.id in address_ids

      # Delete

      params = %{user: nil}

      {:ok, address} = Subject.call(address, params)
      address = reload(address, [:user])

      assert is_nil(address.user)
      assert not is_nil(Repo.get(User, user.id))
    end
  end

  describe "association type: has_many" do
    setup do
      addresses = [
        insert_address!(),
        insert_address!(),
        insert_address!()
      ]

      user = reload(insert_user!(), [:addresses])

      {:ok, addresses: addresses, user: user}
    end

    test "create", %{addresses: addresses, user: user} do
      address1 = Enum.at(addresses, 0)
      address2 = Enum.at(addresses, 1)
      address3 = Enum.at(addresses, 2)

      params = %{addresses: addresses}

      {:ok, user} = Subject.call(user, params)
      address_ids = get_ids(user, :addresses)

      assert length(user.addresses) == 3
      assert address1.id in address_ids
      assert address2.id in address_ids
      assert address3.id in address_ids
    end

    test "update", %{addresses: addresses, user: user} do
      address1 = Enum.at(addresses, 0)
      address2 = Enum.at(addresses, 1)
      address3 = Enum.at(addresses, 2)

      # Create

      {:ok, user} = Subject.call(user, %{addresses: addresses})
      address_ids = get_ids(user, :addresses)

      assert length(user.addresses) == 3
      assert address1.id in address_ids
      assert address2.id in address_ids
      assert address3.id in address_ids

      # Update

      params = %{
        addresses: [
          address1,
          address2
        ]
      }

      {:ok, user} = Subject.call(user, params)
      address_ids = get_ids(user, :addresses)

      assert length(user.addresses) == 2
      assert address1.id in address_ids
      assert address2.id in address_ids
      assert address3.id not in address_ids
    end

    test "delete", %{addresses: addresses, user: user} do
      address1 = Enum.at(addresses, 0)
      address2 = Enum.at(addresses, 1)
      address3 = Enum.at(addresses, 2)

      # Create

      {:ok, user} = Subject.call(user, %{addresses: addresses})
      address_ids = get_ids(user, :addresses)

      assert length(user.addresses) == 3
      assert address1.id in address_ids
      assert address2.id in address_ids
      assert address3.id in address_ids

      # Delete

      params = %{
        addresses: []
      }

      {:ok, user} = Subject.call(user, params)

      assert length(user.addresses) == 0
      assert is_nil(Repo.get(Address, address1.id))
      assert is_nil(Repo.get(Address, address2.id))
      assert is_nil(Repo.get(Address, address3.id))
    end
  end

  describe "association type: has_many lookup table" do
    setup do
      roles = [
        insert_role!(),
        insert_role!(),
        insert_role!()
      ]

      user = reload(insert_user!(), [:user_roles])

      {:ok, roles: roles, user: user}
    end

    test "create: map with ids", %{roles: roles, user: user} do
      role1 = Enum.at(roles, 0)
      role2 = Enum.at(roles, 1)
      role3 = Enum.at(roles, 2)

      params = %{
        user_roles: [
          %{created_by_id: user.id, role_id: role1.id, user_id: user.id},
          %{created_by_id: user.id, role_id: role2.id, user_id: user.id},
          %{created_by_id: user.id, role_id: role3.id, user_id: user.id}
        ]
      }

      {:ok, user} = Subject.call(user, params)
      role_ids = get_ids(user, :roles)

      assert length(user.user_roles) == 3
      assert role1.id in role_ids
      assert role2.id in role_ids
      assert role3.id in role_ids
    end

    test "create: map with structs", %{roles: roles, user: user} do
      role1 = Enum.at(roles, 0)
      role2 = Enum.at(roles, 1)
      role3 = Enum.at(roles, 2)

      params = %{
        user_roles: [
          %{created_by: user, role: role1, user: user},
          %{created_by: user, role: role2, user: user},
          %{created_by: user, role: role3, user: user}
        ]
      }

      {:ok, user} = Subject.call(user, params)
      role_ids = get_ids(user, :roles)

      assert length(user.user_roles) == 3
      assert role1.id in role_ids
      assert role2.id in role_ids
      assert role3.id in role_ids
    end

    test "update", %{roles: roles, user: user} do
      role1 = Enum.at(roles, 0)
      role2 = Enum.at(roles, 1)
      role3 = Enum.at(roles, 2)

      # Create

      params = %{
        user_roles: [
          %{created_by: user, role: role1, user: user},
          %{created_by: user, role: role2, user: user},
          %{created_by: user, role: role3, user: user}
        ]
      }

      {:ok, user} = Subject.call(user, params)
      role_ids = get_ids(user, :roles)

      assert length(user.user_roles) == 3
      assert role1.id in role_ids
      assert role2.id in role_ids
      assert role3.id in role_ids

      # Update

      user_roles =
        user
        |> reload([:user_roles])
        |> Map.get(:user_roles)

      params = %{
        user_roles: [
          List.last(user_roles)
        ]
      }

      {:ok, user} = Subject.call(user, params)
      role_ids = get_ids(user, :roles)

      assert length(user.user_roles) == 1
      assert role1.id not in role_ids
      assert role2.id not in role_ids
      assert role3.id in role_ids
    end

    test "delete", %{roles: roles, user: user} do
      role1 = Enum.at(roles, 0)
      role2 = Enum.at(roles, 1)
      role3 = Enum.at(roles, 2)

      # Create

      params = %{
        user_roles: [
          %{created_by: user, role: role1, user: user},
          %{created_by: user, role: role2, user: user},
          %{created_by: user, role: role3, user: user}
        ]
      }

      {:ok, user} = Subject.call(user, params)
      role_ids = get_ids(user, :roles)

      assert length(user.user_roles) == 3
      assert role1.id in role_ids
      assert role2.id in role_ids
      assert role3.id in role_ids

      # Delete

      params = %{
        user_roles: []
      }

      {:ok, user} = Subject.call(user, params)

      assert length(user.user_roles) == 0
    end
  end

  describe "association type: many_to_many" do
    setup do
      tags = [
        insert_tag!(),
        insert_tag!(),
        insert_tag!()
      ]

      user = reload(insert_user!(), [:tags])

      {:ok, tags: tags, user: user}
    end

    test "create", %{tags: tags, user: user} do
      tag1 = Enum.at(tags, 0)
      tag2 = Enum.at(tags, 1)
      tag3 = Enum.at(tags, 2)

      params = %{tags: tags}

      {:ok, user} = Subject.call(user, params)
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 3
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
      assert tag3.id in tag_ids
    end

    test "update", %{tags: tags, user: user} do
      tag1 = Enum.at(tags, 0)
      tag2 = Enum.at(tags, 1)
      tag3 = Enum.at(tags, 2)

      # Create

      {:ok, user} = Subject.call(user, %{tags: tags})
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 3
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
      assert tag3.id in tag_ids

      # Update

      params = %{
        tags: [
          tag1,
          tag2
        ]
      }

      {:ok, user} = Subject.call(user, params)
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 2
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
      assert tag3.id not in tag_ids
    end

    test "delete", %{tags: tags, user: user} do
      tag1 = Enum.at(tags, 0)
      tag2 = Enum.at(tags, 1)
      tag3 = Enum.at(tags, 2)

      # Create

      {:ok, user} = Subject.call(user, %{tags: tags})
      tag_ids = get_ids(user, :tags)

      assert length(user.tags) == 3
      assert tag1.id in tag_ids
      assert tag2.id in tag_ids
      assert tag3.id in tag_ids

      # Delete

      params = %{
        tags: []
      }

      {:ok, user} = Subject.call(user, params)

      assert length(user.tags) == 0
    end
  end
end
