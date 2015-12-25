defmodule GraphQL.Validation.Rules.ArgumentsOfCorrectTypeTest do
  use ExUnit.Case, async: true

  alias GraphQL.Lang.Parser
  alias GraphQL.Lang.Visitor
  alias GraphQL.Validation.Validator
  alias GraphQL.Validation.Rules

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
    {:ok, document} = Parser.parse("{ greeting(name:123) }")
    context = Validator.context(document, TestSchema.schema)

    Visitor.visit(document)

    Rules.ArgumentsOfCorrectType.validate(context).()
  end
end
