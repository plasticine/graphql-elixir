defmodule GraphQL.Validation.Rules.ArgumentsOfCorrectTypeTest do
  use ExUnit.Case, async: true

  alias GraphQL.Lang.Parser
  alias GraphQL.Validation.Validator

  def assert_validation({query, schema}, expected_output) do
    {:ok, document} = Parser.parse(query)
    assert Validator.validate(schema, document) == expected_output
  end

  defmodule TestSchema do
    def schema do
      %GraphQL.Schema{
        query: %GraphQL.ObjectType{
          name: "RootQueryType",
          fields: %{
            greeting: %{
              type: "String",
              args: %{
                name: %{ type: "String" }
              },
              resolve: &greeting/3,
            }
          }
        }
      }
    end

    def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
    def greeting(_, _, _), do: "Hello, world!"
  end

  test "type is an int" do
    assert_validation {"{ greeting(name:123) }", TestSchema.schema}, {:error, "herp derp"}
  end
end
