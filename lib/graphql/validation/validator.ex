defmodule GraphQL.Validation.Validator do
  alias GraphQL.Lang.Visitor
  alias GraphQL.Validation.Context

  @visitors [
    [Context, :visitor],
    [GraphQL.Validation.Rules.ArgumentsOfCorrectType, :visitor]
  ]

  def validate(schema, document) do
    {:ok, context} = Context.start_link(schema, document)
    visitors = get_visitors(@visitors, [context, schema])
    Visitor.visit(document, visitors)

    case Context.errors(context) do
      {:ok, _}         -> {:ok, document}
      {:error, errors} -> {:error, errors}
    end
  end

  defp get_visitors(visitors, args) do
    visitors
    |> Enum.map(fn([mod, fun]) -> apply(mod, fun, args) end)
    |> Enum.reduce(%{}, fn(x, acc) ->
      Dict.merge(acc, x, fn(_k, v1, v2) ->
        List.flatten([v1] ++ [v2])
      end)
    end)
  end
end