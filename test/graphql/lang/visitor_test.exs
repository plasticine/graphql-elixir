defmodule GraphQL.Lang.Visitor.VisitorTest do
  use ExUnit.Case, async: false

  test "traverses the tree" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b { x }, c }")

    GraphQL.Lang.Visitor.visit(doc, %{
      enter: fn(%{node: node}) ->
        send self, {:enter, node.kind, Dict.get(node, :value)}
      end,
      leave: fn(%{node: node}) ->
        send self, {:leave, node.kind, Dict.get(node, :value)}
      end
    })

    assert_received {:enter, :Document,            nil}
    assert_received {:enter, :OperationDefinition, nil}
    assert_received {:enter, :SelectionSet,        nil}
    assert_received {:enter, :Field,               nil}
    assert_received {:enter, :Name,                "a"}
    assert_received {:leave, :Name,                "a"}
    assert_received {:leave, :Field,               nil}
    assert_received {:enter, :Field,               nil}
    assert_received {:enter, :Name,                "b"}
    assert_received {:leave, :Name,                "b"}
    assert_received {:enter, :SelectionSet,        nil}
    assert_received {:enter, :Field,               nil}
    assert_received {:enter, :Name,                "x"}
    assert_received {:leave, :Name,                "x"}
    assert_received {:leave, :Field,               nil}
    assert_received {:leave, :SelectionSet,        nil}
    assert_received {:leave, :Field,               nil}
    assert_received {:enter, :Field,               nil}
    assert_received {:enter, :Name,                "c"}
    assert_received {:leave, :Name,                "c"}
    assert_received {:leave, :Field,               nil}
    assert_received {:leave, :SelectionSet,        nil}
    assert_received {:leave, :OperationDefinition, nil}
    assert_received {:leave, :Document,            nil}
  end

  test "named functions visitor" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b { x }, c }")

    GraphQL.Lang.Visitor.visit(doc, %{
      Name: fn(%{node: node}) ->
        send self, {:enter, node.kind, Dict.get(node, :value)}
      end,
      SelectionSet: %{
        enter: fn(%{node: node}) ->
          send self, {:enter, node.kind, Dict.get(node, :value)}
        end,
        leave: fn(%{node: node}) ->
          send self, {:leave, node.kind, Dict.get(node, :value)}
        end
      }
    })

    assert_received {:enter, :SelectionSet, nil}
    assert_received {:enter, :Name,         "a"}
    assert_received {:enter, :Name,         "b"}
    assert_received {:enter, :SelectionSet, nil}
    assert_received {:enter, :Name,         "x"}
    assert_received {:leave, :SelectionSet, nil}
    assert_received {:enter, :Name,         "c"}
    assert_received {:leave, :SelectionSet, nil}
  end

  test "kitchen sink" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("""
      # Copyright (c) 2015, Facebook, Inc.

      query queryName($foo: ComplexType, $site: Site = MOBILE) {
        whoever123is: node(id: [123, 456]) {
          id ,
          ... on User @defer {
            field2 {
              id ,
              alias: field1(first:10, after:$foo,) @include(if: $foo) {
                id,
                ...frag
              }
            }
          }
        }
      }

      mutation likeStory {
        like(story: 123) @defer {
          story {
            id
          }
        }
      }

      fragment frag on Friend {
        foo(size: $size, bar: $b, obj: {key: "value"})
      }

      {
        unnamed(truthy: true, falsey: false),
        query
      }
    """)

    GraphQL.Lang.Visitor.visit(doc, %{
      enter: fn(%{node: node, key: key, parent: parent}) ->
        send self, {:enter, node.kind, key, parent && Dict.get(parent, :kind)}
      end,
      leave: fn(%{node: node, key: key, parent: parent}) ->
        send self, {:leave, node.kind, key, parent && Dict.get(parent, :kind)}
      end
    })

    assert_receive {:enter, :Document, nil, nil}
    assert_receive {:enter, :OperationDefinition, 0, nil}
    assert_receive {:enter, :Name, :name, :OperationDefinition}
    assert_receive {:leave, :Name, :name, :OperationDefinition}
    assert_receive {:enter, :VariableDefinition, 0, nil}
    assert_receive {:enter, :Variable, :variable, :VariableDefinition}
    assert_receive {:enter, :Name, :name, :Variable}
    assert_receive {:leave, :Name, :name, :Variable}
    assert_receive {:leave, :Variable, :variable, :VariableDefinition}
    assert_receive {:enter, :NamedType, :type, :VariableDefinition}
    assert_receive {:enter, :Name, :name, :NamedType}
    assert_receive {:leave, :Name, :name, :NamedType}
    assert_receive {:leave, :NamedType, :type, :VariableDefinition}
    assert_receive {:leave, :VariableDefinition, 0, nil}
    assert_receive {:enter, :VariableDefinition, 1, nil}
    assert_receive {:enter, :Variable, :variable, :VariableDefinition}
    assert_receive {:enter, :Name, :name, :Variable}
    assert_receive {:leave, :Name, :name, :Variable}
    assert_receive {:leave, :Variable, :variable, :VariableDefinition}
    assert_receive {:enter, :NamedType, :type, :VariableDefinition}
    assert_receive {:enter, :Name, :name, :NamedType}
    assert_receive {:leave, :Name, :name, :NamedType}
    assert_receive {:leave, :NamedType, :type, :VariableDefinition}
    assert_receive {:enter, :EnumValue, :defaultValue, :VariableDefinition}
    assert_receive {:leave, :EnumValue, :defaultValue, :VariableDefinition}
    assert_receive {:leave, :VariableDefinition, 1, nil}
    assert_receive {:enter, :SelectionSet, :selectionSet, :OperationDefinition}
    assert_receive {:enter, :Field, 0, nil}
    assert_receive {:enter, :Name, :alias, :Field}
    assert_receive {:leave, :Name, :alias, :Field}
    assert_receive {:enter, :Name, :name, :Field}
    assert_receive {:leave, :Name, :name, :Field}
    assert_receive {:enter, :Argument, 0, nil}
    assert_receive {:enter, :Name, :name, :Argument}
    assert_receive {:leave, :Name, :name, :Argument}
    assert_receive {:enter, :ListValue, :value, :Argument}
    assert_receive {:enter, :IntValue, 0, nil}
    assert_receive {:leave, :IntValue, 0, nil}
    assert_receive {:enter, :IntValue, 1, nil}
    assert_receive {:leave, :IntValue, 1, nil}
    assert_receive {:leave, :ListValue, :value, :Argument}
    assert_receive {:leave, :Argument, 0, nil}
    assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    assert_receive {:enter, :Field, 0, nil}
    assert_receive {:enter, :Name, :name, :Field}
    assert_receive {:leave, :Name, :name, :Field}
    assert_receive {:leave, :Field, 0, nil}
    assert_receive {:enter, :InlineFragment, 1, nil}
    assert_receive {:enter, :NamedType, :typeCondition, :InlineFragment}
    assert_receive {:enter, :Name, :name, :NamedType}
    assert_receive {:leave, :Name, :name, :NamedType}
    assert_receive {:leave, :NamedType, :typeCondition, :InlineFragment}
    assert_receive {:enter, :Directive, 0, nil}
    assert_receive {:enter, :Name, :name, :Directive}
    assert_receive {:leave, :Name, :name, :Directive}
    assert_receive {:leave, :Directive, 0, nil}
    assert_receive {:enter, :SelectionSet, :selectionSet, :InlineFragment}
    assert_receive {:enter, :Field, 0, nil}
    assert_receive {:enter, :Name, :name, :Field}
    assert_receive {:leave, :Name, :name, :Field}
    assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    assert_receive {:enter, :Field, 0, nil}
    assert_receive {:enter, :Name, :name, :Field}
    assert_receive {:leave, :Name, :name, :Field}
    assert_receive {:leave, :Field, 0, nil}
    assert_receive {:enter, :Field, 1, nil}
    assert_receive {:enter, :Name, :alias, :Field}
    assert_receive {:leave, :Name, :alias, :Field}
    assert_receive {:enter, :Name, :name, :Field}
    assert_receive {:leave, :Name, :name, :Field}
    assert_receive {:enter, :Argument, 0, nil}
    assert_receive {:enter, :Name, :name, :Argument}
    assert_receive {:leave, :Name, :name, :Argument}
    assert_receive {:enter, :IntValue, :value, :Argument}
    assert_receive {:leave, :IntValue, :value, :Argument}
    assert_receive {:leave, :Argument, 0, nil}
    assert_receive {:enter, :Argument, 1, nil}
    assert_receive {:enter, :Name, :name, :Argument}
    assert_receive {:leave, :Name, :name, :Argument}
    assert_receive {:enter, :Variable, :value, :Argument}
    assert_receive {:enter, :Name, :name, :Variable}
    assert_receive {:leave, :Name, :name, :Variable}
    assert_receive {:leave, :Variable, :value, :Argument}
    assert_receive {:leave, :Argument, 1, nil}
    assert_receive {:enter, :Directive, 0, nil}
    assert_receive {:enter, :Name, :name, :Directive}
    assert_receive {:leave, :Name, :name, :Directive}
    assert_receive {:enter, :Argument, 0, nil}
    assert_receive {:enter, :Name, :name, :Argument}
    assert_receive {:leave, :Name, :name, :Argument}
    assert_receive {:enter, :Variable, :value, :Argument}
    assert_receive {:enter, :Name, :name, :Variable}
    assert_receive {:leave, :Name, :name, :Variable}
    assert_receive {:leave, :Variable, :value, :Argument}
    assert_receive {:leave, :Argument, 0, nil}
    assert_receive {:leave, :Directive, 0, nil}
    assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    assert_receive {:enter, :Field, 0, nil}
    assert_receive {:enter, :Name, :name, :Field}
    assert_receive {:leave, :Name, :name, :Field}
    assert_receive {:leave, :Field, 0, nil}
    assert_receive {:enter, :FragmentSpread, 1, nil}
    assert_receive {:enter, :Name, :name, :FragmentSpread}
    assert_receive {:leave, :Name, :name, :FragmentSpread}
    assert_receive {:leave, :FragmentSpread, 1, nil}
    assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    assert_receive {:leave, :Field, 1, nil}
    assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    assert_receive {:leave, :Field, 0, nil}
    assert_receive {:leave, :SelectionSet, :selectionSet, :InlineFragment}
    assert_receive {:leave, :InlineFragment, 1, nil}
    # assert_receive {:enter, :InlineFragment, 2, nil}
    # assert_receive {:enter, :Directive, 0, nil}
    # assert_receive {:enter, :Name, :name, :Directive}
    # assert_receive {:leave, :Name, :name, :Directive}
    # assert_receive {:enter, :Argument, 0, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :Variable, :value, :Argument}
    # assert_receive {:enter, :Name, :name, :Variable}
    # assert_receive {:leave, :Name, :name, :Variable}
    # assert_receive {:leave, :Variable, :value, :Argument}
    # assert_receive {:leave, :Argument, 0, nil}
    # assert_receive {:leave, :Directive, 0, nil}
    # # assert_receive {:enter, :SelectionSet, :selectionSet, :InlineFragment}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # # assert_receive {:leave, :SelectionSet, :selectionSet, :InlineFragment}
    # # assert_receive {:leave, :InlineFragment, 2, nil}
    # # assert_receive {:enter, :InlineFragment, 3, nil}
    # # assert_receive {:enter, :SelectionSet, :selectionSet, :InlineFragment}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # # assert_receive {:leave, :SelectionSet, :selectionSet, :InlineFragment}
    # # assert_receive {:leave, :InlineFragment, 3, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :OperationDefinition}
    # assert_receive {:leave, :OperationDefinition, 0, nil}
    # assert_receive {:enter, :OperationDefinition, 1, nil}
    # assert_receive {:enter, :Name, :name, :OperationDefinition}
    # assert_receive {:leave, :Name, :name, :OperationDefinition}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :OperationDefinition}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:enter, :Argument, 0, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :IntValue, :value, :Argument}
    # assert_receive {:leave, :IntValue, :value, :Argument}
    # assert_receive {:leave, :Argument, 0, nil}
    # # assert_receive {:enter, :Directive, 0, nil}
    # # assert_receive {:enter, :Name, :name, :Directive}
    # # assert_receive {:leave, :Name, :name, :Directive}
    # # assert_receive {:leave, :Directive, 0, nil}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :OperationDefinition}
    # assert_receive {:leave, :OperationDefinition, 1, nil}
    # # assert_receive {:enter, :OperationDefinition, 2, nil}
    # # assert_receive {:enter, :Name, :name, :OperationDefinition}
    # # assert_receive {:leave, :Name, :name, :OperationDefinition}
    # # assert_receive {:enter, :VariableDefinition, 0, nil}
    # # assert_receive {:enter, :Variable, :variable, :VariableDefinition}
    # assert_receive {:enter, :Name, :name, :Variable}
    # assert_receive {:leave, :Name, :name, :Variable}
    # # assert_receive {:leave, :Variable, :variable, :VariableDefinition}
    # # assert_receive {:enter, :NamedType, :type, :VariableDefinition}
    # assert_receive {:enter, :Name, :name, :NamedType}
    # assert_receive {:leave, :Name, :name, :NamedType}
    # # assert_receive {:leave, :NamedType, :type, :VariableDefinition}
    # # assert_receive {:leave, :VariableDefinition, 0, nil}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :OperationDefinition}
    # # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:enter, :Argument, 0, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :Variable, :value, :Argument}
    # # assert_receive {:enter, :Name, :name, :Variable}
    # # assert_receive {:leave, :Name, :name, :Variable}
    # assert_receive {:leave, :Variable, :value, :Argument}
    # assert_receive {:leave, :Argument, 0, nil}
    # # assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    # # assert_receive {:enter, :Field, 0, nil}
    # # assert_receive {:enter, :Name, :name, :Field}
    # # assert_receive {:leave, :Name, :name, :Field}
    # # assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    # # assert_receive {:enter, :Field, 0, nil}
    # # assert_receive {:enter, :Name, :name, :Field}
    # # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:enter, :Field, 1, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:leave, :Field, 1, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :Field}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :OperationDefinition}
    # # assert_receive {:leave, :OperationDefinition, 2, nil}
    # # assert_receive {:enter, :FragmentDefinition, 3, nil}
    # assert_receive {:enter, :Name, :name, :FragmentDefinition}
    # assert_receive {:leave, :Name, :name, :FragmentDefinition}
    # assert_receive {:enter, :NamedType, :typeCondition, :FragmentDefinition}
    # assert_receive {:enter, :Name, :name, :NamedType}
    # assert_receive {:leave, :Name, :name, :NamedType}
    # assert_receive {:leave, :NamedType, :typeCondition, :FragmentDefinition}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :FragmentDefinition}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:enter, :Argument, 0, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :Variable, :value, :Argument}
    # assert_receive {:enter, :Name, :name, :Variable}
    # assert_receive {:leave, :Name, :name, :Variable}
    # assert_receive {:leave, :Variable, :value, :Argument}
    # assert_receive {:leave, :Argument, 0, nil}
    # assert_receive {:enter, :Argument, 1, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :Variable, :value, :Argument}
    # assert_receive {:enter, :Name, :name, :Variable}
    # assert_receive {:leave, :Name, :name, :Variable}
    # assert_receive {:leave, :Variable, :value, :Argument}
    # assert_receive {:leave, :Argument, 1, nil}
    # assert_receive {:enter, :Argument, 2, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :ObjectValue, :value, :Argument}
    # assert_receive {:enter, :ObjectField, 0, nil}
    # assert_receive {:enter, :Name, :name, :ObjectField}
    # assert_receive {:leave, :Name, :name, :ObjectField}
    # assert_receive {:enter, :StringValue, :value, :ObjectField}
    # assert_receive {:leave, :StringValue, :value, :ObjectField}
    # assert_receive {:leave, :ObjectField, 0, nil}
    # assert_receive {:leave, :ObjectValue, :value, :Argument}
    # assert_receive {:leave, :Argument, 2, nil}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :FragmentDefinition}
    # # assert_receive {:leave, :FragmentDefinition, 3, nil}
    # # assert_receive {:enter, :OperationDefinition, 4, nil}
    # assert_receive {:enter, :SelectionSet, :selectionSet, :OperationDefinition}
    # assert_receive {:enter, :Field, 0, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:enter, :Argument, 0, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :BooleanValue, :value, :Argument}
    # assert_receive {:leave, :BooleanValue, :value, :Argument}
    # assert_receive {:leave, :Argument, 0, nil}
    # assert_receive {:enter, :Argument, 1, nil}
    # assert_receive {:enter, :Name, :name, :Argument}
    # assert_receive {:leave, :Name, :name, :Argument}
    # assert_receive {:enter, :BooleanValue, :value, :Argument}
    # assert_receive {:leave, :BooleanValue, :value, :Argument}
    # assert_receive {:leave, :Argument, 1, nil}
    # assert_receive {:leave, :Field, 0, nil}
    # assert_receive {:enter, :Field, 1, nil}
    # assert_receive {:enter, :Name, :name, :Field}
    # assert_receive {:leave, :Name, :name, :Field}
    # assert_receive {:leave, :Field, 1, nil}
    # assert_receive {:leave, :SelectionSet, :selectionSet, :OperationDefinition}
    # # assert_receive {:leave, :OperationDefinition, 4, nil}
    # assert_receive {:leave, :Document, nil, nil}
  end
end
