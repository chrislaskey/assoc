defmodule Assoc.Test.Factories do
  alias Assoc.Test.Address
  alias Assoc.Test.Repo
  alias Assoc.Test.Role
  alias Assoc.Test.Tag
  alias Assoc.Test.User

  # Factories

  def insert_address!(params \\ %{}) do
    default_params = %{
      address: "test address"
    }

    params = Map.merge(default_params, params)

    %Address{}
    |> Address.changeset(params)
    |> Repo.insert!()
  end

  def insert_tag!(params \\ %{}) do
    default_params = %{
      name: "test tag"
    }

    params = Map.merge(default_params, params)

    %Tag{}
    |> Tag.changeset(params)
    |> Repo.insert!()
  end

  def insert_role!(params \\ %{}) do
    default_params = %{
      name: "test role"
    }

    params = Map.merge(default_params, params)

    %Role{}
    |> Role.changeset(params)
    |> Repo.insert!()
  end

  def insert_user!(params \\ %{}) do
    default_params = %{
      email: "test@example.com"
    }

    params = Map.merge(default_params, params)

    %User{}
    |> User.changeset(params)
    |> Repo.insert!()
  end
end
