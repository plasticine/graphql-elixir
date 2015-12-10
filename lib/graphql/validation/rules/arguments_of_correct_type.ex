# https://github.com/graphql/graphql-js/blob/master/src/validation/rules/ArgumentsOfCorrectType.js
defmodule GraphQL.Validation.Rules.ArgumentsOfCorrectType do
  def validate(context) do
    require IEx; IEx.pry
    # IO.inspect context.document.definitions
    # IO.inspect context.schema
  end
end
