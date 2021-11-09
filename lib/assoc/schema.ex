defmodule Assoc.Schema do
  @moduledoc """
  ## Usage

  ```
  defmodule MyApp.User do
    use MyApp.Schema
    use Assoc.Schema, repo: MyApp.Repo

    schema "users" do
      field :email, :string
      field :name, :string
      has_many :user_roles, MyApp.UserRole, on_delete: :delete_all, on_replace: :delete
      timestamps()
    end

    def updatable_associations, do: [
      user_roles: MyApp.UserRole
    ]

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:email, :name])
      |> validate_required([:email])
    end
  end
  ```

  Key points:

  - The `use Assoc.Schema` line should come after `use MyApp.Schema`.
  - Pass the app's Repo into `use Assoc.Schema, repo: MyApp.Repo`
  - Define a `updatable_associations` function. For each updatable association:
    - The `key` should be the association name
    - The `value` should be the association schema module
  - The standard `changeset` function does not change.
    - Include all the standard code for updating struct values (e.g. name, email) in `changeset`
    - The library will create and use a separate `associations_changeset` to manage the associations
  """

  @callback updatable_associations :: list()

  defmacro __using__(repo: repo) do
    quote do
      @doc """
      Preload all schema associations.

      ## Usage

      ```
      MyApp.User.preload_all(user)
      ```

      ## Implementation

      Builds a list of keys with `Ecto.Association.NotLoaded` values. Then
      feeds the list into `Repo.preload`.
      """
      def preload_all(struct) do
        keys =
          struct
          |> Map.from_struct()
          |> Enum.reduce([], fn {key, value}, acc ->
            case value do
              %Ecto.Association.NotLoaded{} -> [key | acc]
              _ -> acc
            end
          end)

        unquote(repo).preload(struct, keys)
      end

      @doc """
      Update associations defined in `updatable_associations/0` callback.
      """
      def associations_changeset(struct, params \\ %{}) do
        struct = preload_associations(struct, updatable_associations())
        params = include_existing_associations(struct, params)

        struct
        |> Ecto.Changeset.cast(params, [])
        |> put_associations(updatable_associations(), params)
      end

      @doc """
      Preload selected schema associations.
      """
      def preload_associations(struct, associations) do
        associations =
          case Keyword.keyword?(associations) do
            true -> Keyword.keys(associations)
            false -> associations
          end

        unquote(repo).preload(struct, associations)
      end

      # Include existing associations in params by merging params into preload struct
      defp include_existing_associations(struct, params) do
        struct
        |> Map.from_struct()
        |> Map.merge(params)
      end

      # Dynamically adds `put_assoc` calls to changeset
      defp put_associations(changeset, associations, params) do
        Enum.reduce(associations, changeset, fn {key, _}, acc ->
          value =
            params
            |> Assoc.Util.keys_to_atoms()
            |> Map.get(key, :omitted)

          case value do
            :omitted -> acc
            value -> Ecto.Changeset.put_assoc(acc, key, value)
          end
        end)
      end
    end
  end
end
