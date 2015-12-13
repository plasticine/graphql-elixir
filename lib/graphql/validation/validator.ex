defmodule GraphQL.Validation.Validator do
  def validate(schema, document) do
    context = %GraphQL.Validation.Context{schema: schema, document: document}
    rules
    |> Enum.map(fn(rule) -> apply(rule, :validate, [context]) end)
    |> visit(document)

    case GraphQL.Validation.Context.getErrors(context) do
      {:ok, _}         -> {:ok, document}
      {:error, errors} -> {:error, errors}
    end
  end

  defp visit(visitors, document) do

  end

  defp rules do
    [
      GraphQL.Validation.Rules.ArgumentsOfCorrectType
    ]
  end
end
