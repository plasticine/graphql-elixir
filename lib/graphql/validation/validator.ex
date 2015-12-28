defmodule GraphQL.Validation.Validator do
  alias GraphQL.Lang.Visitor

  @visitors [
    GraphQL.Validation.Rules.ArgumentsOfCorrectType,
    GraphQL.Validation.Rules.ArgumentsOfCorrectType,
    GraphQL.Validation.Rules.ArgumentsOfCorrectType
  ]

  def validate(schema, document) do
    context = %GraphQL.Validation.Context{schema: schema, document: document}
    Visitor.visit(document, get_visitors(@visitors, context))

    IO.inspect get_visitors(@visitors, context)

    case GraphQL.Validation.Context.getErrors(context) do
      {:ok, _}         -> {:ok, document}
      {:error, errors} -> {:error, errors}
    end
  end

  defp get_visitors(visitors, context) do
    visitors
    |> Enum.map(fn(rule) -> apply(rule, :visitor, []) end)
    |> Enum.reduce(%{}, fn(x, acc) ->
      Dict.merge(acc, x, fn(_k, v1, v2) ->
        List.flatten([v1] ++ [v2])
      end)
    end)
  end
end
