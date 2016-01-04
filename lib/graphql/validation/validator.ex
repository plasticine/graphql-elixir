defmodule GraphQL.Validation.Validator do
  alias GraphQL.Lang.Visitor
  alias GraphQL.Utilities.TypeInfo
  alias GraphQL.Validation.Context

  @visitors [
    [__MODULE__, :context_visitor],

    # Rules
    [GraphQL.Validation.Rules.ArgumentsOfCorrectType, :visitor]
  ]

  def validate(schema, document) do
    {:ok, context} = Context.start_link(schema, document)
    visitors = get_visitors(@visitors, [schema, context])
    Visitor.visit(document, visitors)

    IO.inspect Context.errors(context)

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

  def context_visitor(schema, context) do
    %{
      enter: fn(args) ->
        Context.type_info(context, TypeInfo.enter(schema, args.item))
      end,
      leave: fn(args) ->
        Context.type_info(context, TypeInfo.leave(schema, args.item))
      end
    }
  end
end
