defmodule GraphQL.Validation.Validator do
  alias GraphQL.Lang.Visitor

  def validate(schema, document) do
    context = context(schema, document)
    rules
    |> Enum.map(fn(rule) -> apply(rule, :validate, [context]) end)
    |> Visitor.visit(document)

    case GraphQL.Validation.Context.getErrors(context) do
      {:ok, _}         -> {:ok, document}
      {:error, errors} -> {:error, errors}
    end
  end

  def context(schema, document) do
    %GraphQL.Validation.Context{schema: schema, document: document}
  end

  defp rules do
    [
      GraphQL.Validation.Rules.ArgumentsOfCorrectType
    ]
  end
end
