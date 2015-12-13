defmodule GraphQL.Utilities do
  @doc """
  Utility for validators which determines if a value literal AST is valid given
  an input type.

  Note that this only validates literal values, variables are assumed to
  provide values of the correct type.
  """
  def is_valid_literal_value(type, value) do
    # case type do
    #   # A value must be provided if the type is non-null.
    #   %GraphQL.NonNull{} ->

    #   # Lists accept a non-list value as a list of one.
    #   #
    #   # Not currently implemented as I'm not sure that we support this at present.
    #   # https://github.com/graphql/graphql-js/blob/master/src/utilities/isValidLiteralValue.js#L65
    #   %GraphQL.List{} ->
    # end
  end
end
