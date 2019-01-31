# Assoc

> Tired of writing custom boilerplate to manage database associations in ecto?

Ecto is an incredibly powerful toolkit, and it's flexible enough to fit all kinds of database designs. That flexibility also means you sometimes end up writing a lot of code to accomplish a simple pattern.

Assoc simplifies the code needed to manage common Ecto associations without the custom code and boilerplate. Drop in a `use` statement and define which associations are updatable. It's that easy.

[![Build Status](https://travis-ci.com/chrislaskey/assoc.svg?branch=master)](https://travis-ci.com/chrislaskey/assoc)

## Quickstart

In the schema file, include `Assoc.Schema` and define which associations can be updated:

```elixir
defmodule MyApp.User do
  use MyApp.Schema
  use Assoc.Schema, repo: MyApp.Repo

  schema "users" do
    many_to_many :tags, MyApp.Tag, join_through: "tags_users", on_replace: :delete
  end

  def updatable_associations, do: [
    tags: MyApp.Tag
  ]
end
```

Then update the associations:

```elixir
import Assoc.Updater

params = %{
  tags: [
    %{id: 5}, # Associate existing tag
    %{id: 8, name: "updated name"}, # Associate and update the name of an existing tag
    %{name: "new tag"} # Create and associate new tag
  ]
}

update_associations(MyApp.Repo, user, params)
```

## How It Works

The power of Ecto is that it can be used to fit all kinds of database topologies. The goal of Assoc is to reduce the amount of code needed for some of the most common ones. It's not a replacement for learning Ecto. In fact, under the covers all it's doing is making common ecto calls. Don't let the learning curve of Ecto be intimidating!

### Understanding the Danger

The first step to dispelling the magic is knowing Assoc uses `put_assoc` to generate a changeset. As a consequence, this means:

> If an association key is included in the params, then the existing associations will be replaced by the param value. This means records can be deleted. When passing association values, always include every association.

### The Good Parts

With the potential for data loss in mind, Assoc adds some guard-rails and quality of life improvements like:

> If an association key is not included in the params, then the existing associations will not be changed. All the existing associations will remain.

### Step by Step Example

Let's walk through the quickstart example to see each step in action.

```elixir
params = %{
  tags: [
    %{id: 5}, # Associate existing tag
    %{id: 8, name: "updated name"}, # Associate and update the name of an existing tag
    %{name: "new tag"} # Create and associate new tag
  ]
}

update_associations(MyApp.Repo, user, params)
```

The first thing that happens is the `user` record is examined. The associated struct `MyApp.User` is found, and the `updatable_associations` function defined in the schema file is read.

```elixir
def updatable_associations, do: [
  tags: MyApp.Tag
]
```

From there, each of the updatable associations is walked through, checking the params for a matching key. When a matching key is found, each value is walked through. In the case of a `has_many` or `many_to_many` this will be a list of values.

#### Associating an Existing Tag

Taking the first value:

```elixir
%{id: 5}
```

To help with `belongs_to` associations, the `user` record id is included in the params:

```elixir
%{id: 5, user_id: user.id}
```

Thanks to how changesets work, this will be silently removed by associations that don't use it. But available for those that do.

Next it searches the database for an existing `MyApp.Tag` record by the `id` value. If one is found, then the record is updated and returned:

```elixir
tag_record
|> MyApp.Tag.changeset(params)
|> MyApp.Repo.update
```

#### Associating and Updating an Existing Tag

The same process is repeated for the second example:

```elixir
%{id: 8, name: "updated name"}
```

The only difference is since this includes attributes like `name`, the association values are also updated.

#### Creating a New Tag

For the last example payload:

```elixir
%{name: "new tag"}
```

This one doesn't have an `id`, so instead a record is inserted instead of updated:

```elixir
%MyApp.Tag{}
|> MyApp.Tag.changeset(params)
|> MyApp.Repo.insert
```

Now that the three `tag` records have been created or updated, they are ready to be passed into a `user` changeset with `put_assoc`:

```elixir
%{
  tags: [
    %MyApp.Tag{id: 5},
    %MyApp.Tag{id: 8},
    %MyApp.Tag{id: 10}
  ]
}
```

For each association param, a `put_assoc` is dynamically added before updating the record:

```elixir
user
|> MyApp.User.associations_changeset(params)
|> MyApp.Repo.update
```

## Usage

The same code works for `many_to_many`, `has_many`, and `belongs_to` associations.

### Using with Pipes

Though the direct call used in the quickstart is handy:

```elixir
update_associations(MyApp.Repo, user, params)
```

Having to pass in `MyApp.Repo` as the first argument isn't very pipe friendly.

To help with this, Assoc supports including the library in a module and passing the repo as an option:

```elixir
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

This removes the requirement to explicitly pass `MyApp.Repo`. To make it even more pipe friendly, the `update_associations` function can take either a `record` directly or a `{:ok, record}` tuple. Any other values are silently returned.

### Params

The `update_associations` function accepts a wide variety of data sources for association params.

It takes Structs:

```elixir
[
  %MyApp.Tag{id: 5, name: "existing tag"},
  %MyApp.Tag{name: "new tag"}
]
```

As well as Maps:

```elixir
[
  %{id: 5, name: "existing tag"},
  %{"id" => "8", "name" => "existing tag, too"},
  %{"name" => "new tag"}
]
```

Or any combination of both:

```elixir
[
  %MyApp.Tag{id: 5, name: "existing tag"},
  %{"name" => "new tag"}
]
```

## Examples

Additional examples showing `belongs_to`, `has_many` and `many_to_many` associations are included in the tests:

- [Test Schemas](https://github.com/chrislaskey/assoc/tree/master/test/setup/schemas)
- [Test Schema Migrations](https://github.com/chrislaskey/assoc/tree/master/priv/repo/migrations)
- [Tests](https://github.com/chrislaskey/assoc/tree/master/test/assoc/updater_test.exs)

## Frequently Asked Questions

### Why not use `cast_assoc`?

Ecto's `cast_assoc` is great for when associations are always managed through a parent. To illustrate its limitations, take the following example:

```elixir
params = %{
  tags: [
    %{id: existing_tag.id, name: "Existing Tag"}
  ]
}
```

When using `cast_assoc`, if the existing tag is already associated with the parent then it'll stay associated, and any values like `name` will be updated.

Now, what if the tag already exists in the database but isn't associated with the parent? One might expect the behaviour to be the same - associate the tag with the parent record and update the values. Though a reasonable assumption, it's wrong.

What actually happens is the `id` value is ignored, acting as if it were passed:

```elixir
params = %{
  tags: [
    %{name: "Existing Tag"}
  ]
}
```

As a result, Ecto will try to create a new tag entry. Depending on the applications constraints, this will either blow up on a uniqueness validation or create two competing tags with the same name.

### `put_assoc` to the rescue

This example highlights how `cast_assoc` isn't meant to manage cases where a record already exists before being associated with a record. Instead, that's the domain of  `put_assoc`.

When dealing with existing associations, there's a lot more edge cases to deal with. Without the tighter constraints `cast_assoc` operates in, `put_assoc` can't automatically manage the relationships without making assumptions. As a result, `put_assoc` only handles associating existing records, without the ability to create new or update existing associations.

The good news is ecto gives us the tools to write our own custom code to achieve the same results:

- Create new records if they don't exist
- Update existing records if they do exist
- Associate all created and updated records with the parent

And that is exactly what Assoc is written to do. It takes the common case, wraps it up in an easy to use interface, and delivers the expected functionality without having to write it yourself.

It won't fit every database design - it can't. But it does solve the common case, and gives a good jumping off point for writing custom solutions where it can't.

The best part, is the same pattern works just as well for `has_many` as it does for `many_to_many`.

### Is this a good idea? [You don't have take my word for it](https://www.youtube.com/watch?v=vAvQbEeTafk)

> put_assoc is also a good choice when you’re managing parent and child records separately, even when working with external data. You could for example use changesets to create/update/delete the child records on their own, then use put_assoc in a separate changeset to update the collection on the parent record. This is often a great way to work with many-to-many associations.
>
> — [Programming Ecto](https://pragprog.com/book/wmecto/programming-ecto), Chapter 4, Working with Associations.
