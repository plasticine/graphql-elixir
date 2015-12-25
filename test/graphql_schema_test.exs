defmodule GraphQL.SchemaTest do
  use ExUnit.Case

  defmodule Person do
    use GraphQL.Object

    field :id
    field :name
    field :age
  end

  defmodule TestSchema do
    use GraphQL.Schema

    field :person, type: person do
      argument :id, description: "id of the person", null: false

      resolve %{id: id} do
        getHuman(id)
      end
    end
  end

  test "a GraphQL object contains a meta module" do
    context = [
      %Person{id: 1, name: "Nick", age: 32}
      %Person{id: 2, name: "Jane", age: 28}
      %Person{id: 3, name: "Doug", age: 36}
    ]

    assert Person.Meta.fields == [sex: [], age: [], name: []]

    query = "{ person(id: 1) { name } }"
    assert GraphQL.execute(TestSchema, query) == [data: [name: "Nick"]]
  end
end
