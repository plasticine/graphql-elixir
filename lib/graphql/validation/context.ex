defmodule GraphQL.Validation.Context do
  defstruct schema: nil, document: nil, errors: []

  def get do
    IO.puts "hello world"
  end

  def getErrors(context) do
    {:ok, []}
  end

  def getArgument(context) do
    {:ok, nil}
  end
end
