defmodule GraphQL.Validation.Context do
  defstruct schema: nil, document: nil, errors: []

  def get do
    IO.puts "hello world"
  end

  def getErrors(context) do
    {:ok, []}
  end
end
