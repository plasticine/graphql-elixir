defmodule GraphQL.Validation.Context do
  defstruct schema: nil, document: nil, errors: []

  def getErrors(context) do
    {:ok, []}
  end
end
