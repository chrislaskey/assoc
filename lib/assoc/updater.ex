defmodule Assoc.Updater do
  @moduledoc """
  ## Usage

  ### Within a Module

  ```
  defmodule MyApp.CreateUser do
    use Assoc.Updater, repo: MyApp.Repo

    def call(params) do
      %User{}
      |> User.changeset(params)
      |> Repo.insert
      |> update_associations(params)
    end
  end
  ```

  Key points:

  - Include `use Assoc.Updater` at the top of the module
  - Add `update_associations` after the record is created / updated
    - The first argument is the parent struct. It can take the struct on its own, or in a tuple:
      - `%User{}`
      - `{:ok, %User{}}`
      - Any other values are returned without raising an exception
    - The second argument is the params.

  ### Direct Function Call

  ```
  Assoc.Updater.update_associations(MyApp.Repo, user, params)
  ```

  Key points:

  - The first argument is the Repo module to use for database interactions.
  - The second argument is the parent struct. It can take the struct on its own, or in a tuple:
  - The third argument is the params.

  """

  @doc """
  Create and update associated records.
  """
  @spec update_associations(map(), struct() | {:ok, struct()}, map()) ::
          {:ok, Map.t()} | {:error, String.t()}
  def update_associations(repo, {:ok, parent}, params),
    do: update_associations(repo, parent, params)

  def update_associations(repo, schema = %{} = parent, params) do
    associations =
      Enum.reduce(schema.updatable_associations, %{}, fn {association_key, association_schema},
                                                         acc ->
        association_params =
          params
          |> Assoc.Util.keys_to_atoms()
          |> Map.get(association_key, :omitted)

        case update_association(repo, parent, association_schema, association_params) do
          {:skipped, _} -> acc
          {:error, error} -> Map.put(acc, association_key, error)
          {:ok, result} -> Map.put(acc, association_key, result)
        end
      end)

    parent
    |> schema.associations_changeset(associations)
    |> repo.update
  end

  def update_associations(_, value, _), do: value

  # Create or update records for a specific association.
  defp update_association(_repo, _parent, _schema, nil), do: {:ok, nil}
  defp update_association(_repo, _parent, schema, :omitted), do: {:skipped, schema}

  defp update_association(repo, parent, schema, params) when is_list(params) do
    results =
      Enum.map(params, fn record_params ->
        case create_or_update(repo, parent, schema, record_params) do
          {:error, error} -> throw(error)
          {:ok, result} -> result
        end
      end)

    {:ok, results}
  catch
    %{} = error -> {:error, error}
    error -> raise error
  end

  defp update_association(repo, parent, schema, params) do
    result =
      case create_or_update(repo, parent, schema, params) do
        {:error, error} -> throw(error)
        {:ok, result} -> result
      end

    {:ok, result}
  catch
    %{} = error -> {:error, error}
    error -> raise error
  end

  # Create or update associated record.
  defp create_or_update(repo, parent, schema, params) do
    params =
      params
      |> add_parent_to_params(parent)
      |> add_association_ids_to_params

    case Map.get(params, :id) do
      nil ->
        schema.__struct__
        |> schema.changeset(params)
        |> repo.insert()

      id ->
        schema
        |> repo.get(id)
        |> schema.changeset(params)
        |> repo.update()
    end
  end

  # Add a reference to the parent record into params.
  #
  # Given:
  #
  #   add_parent_to_params(%{role_id: 5}, %UserGroup{id: 3})
  #
  # Returns:
  #
  #   %{role_id: 5, user_group: %UserGroup{id: 3}, user_group_id: 3}
  defp add_parent_to_params(%_struct{} = params, parent),
    do: add_parent_to_params(Map.from_struct(params), parent)

  defp add_parent_to_params(params, parent) do
    name =
      parent.__struct__
      |> Atom.to_string()
      |> String.split(".")
      |> List.last()
      |> Macro.underscore()

    params
    |> Assoc.Util.keys_to_atoms()
    |> Map.put(String.to_atom(name), parent)
    |> Map.put(String.to_atom("#{name}_id"), parent.id)
  end

  # Add a reference to the association record id in params. Only adds a key
  # if the value is a map or struct that contains an `id` key.
  #
  # Given:
  #
  #   add_parent_to_params(%{
  #     role: %Role{id: 8, name: "role"},
  #     user: %{id: 5, name: "user"},
  #     user_role: %{name: "user role"}
  #   })
  #
  # Returns:
  #
  #   %{
  #     role: %Role{id: 1, name: "role"},
  #     role_id: 8,
  #     user: %{id: 1, name: "user"},
  #     user_id: 5,
  #     user_role: %{name: "user role"}
  #   }
  defp add_association_ids_to_params(params) do
    Enum.reduce(params, params, fn {key, value}, acc ->
      case is_map(value) && Map.get(value, :id, false) do
        false -> acc
        id -> Map.put(acc, String.to_atom("#{key}_id"), id)
      end
    end)
  end

  defmacro __using__(repo: repo) do
    quote do
      import Assoc.Updater

      @spec update_associations(struct() | {:ok, struct()}, map()) ::
              {:ok, Map.t()} | {:error, String.t()}
      def update_associations(parent, params) do
        update_associations(unquote(repo), parent, params)
      end
    end
  end
end
