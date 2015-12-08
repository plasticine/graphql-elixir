defmodule GraphQL.Validation.Validator do
  def validate(schema, document) do
    context = validation_context(schema, document)
    rules |> Enum.map(fn(mod) -> apply(mod, :validate, [context]) end)

    {:ok, document}
  end

  defp validation_context(schema, document) do
    %{
      schema: schema,
      document: document,
      errors: []
    }
  end

  defp rules do
    [
      GraphQL.Validation.Rules.ArgumentsOfCorrectType
    ]
  end
end
