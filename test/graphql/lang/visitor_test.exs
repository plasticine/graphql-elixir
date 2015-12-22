defmodule GraphQL.Lang.Visitor.VisitorTest do
  use ExUnit.Case, async: true

  # test "WIP" do
  #   {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b, c { a, b, c } }")
  #   GraphQL.Lang.Visitor.visit(doc, %{})
  # end

  test "traverses the tree" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b { x }, c }")

    GraphQL.Lang.Visitor.visit(doc, %{
      enter: fn(node, _, _, _, _) ->
        send self, {:enter, node.kind, Dict.get(node, :value)}
      end,
      leave: fn(node, _, _, _, _) ->
        send self, {:leave, node.kind, Dict.get(node, :value)}
      end
    })

    # TODO: this is incorrect
    # assert_receive {:enter, :Document, nil}
    assert_receive {:enter, :OperationDefinition, nil}
    assert_receive {:enter, :SelectionSet, nil}
    assert_receive {:enter, :Field, nil}
    assert_receive {:enter, :Name, "a"}
    assert_receive {:leave, :Name, "a"}
    assert_receive {:leave, :Field, nil}
    assert_receive {:enter, :Field, nil}
    assert_receive {:enter, :Field, nil}
    assert_receive {:enter, :Name, "c"}
    assert_receive {:leave, :Name, "c"}
    assert_receive {:leave, :Field, nil}
    assert_receive {:leave, :SelectionSet, nil}
    assert_receive {:leave, :OperationDefinition, nil}
    assert_receive {:leave, :Document, nil}
  end

  test "named functions visitor" do
    {:ok, doc} = GraphQL.Lang.Parser.parse("{ a, b { x }, c }")

    GraphQL.Lang.Visitor.visit(doc, %{
      Name: fn(node, _, _, _, _) ->
        send self, {:enter, node.kind, Dict.get(node, :value)}
      end,
      SelectionSet: %{
        enter: fn(node, _, _, _, _) ->
          send self, {:enter, node.kind, Dict.get(node, :value)}
        end,
        leave: fn(node, _, _, _, _) ->
          send self, {:leave, node.kind, Dict.get(node, :value)}
        end
      }
    })

    assert_receive {:enter, :SelectionSet, nil}
    assert_receive {:enter, :Name,         "a"}
    assert_receive {:enter, :Name,         "b"}
    assert_receive {:enter, :SelectionSet, nil}
    assert_receive {:enter, :Name,         "x"}
    assert_receive {:leave, :SelectionSet, nil}
    assert_receive {:enter, :Name,         "c"}
    assert_receive {:leave, :SelectionSet, nil}
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
      enter: fn(node, _, _, _, _) ->
        send self, {:enter, node.kind, Dict.get(node, :value)}
      end,
      leave: fn(node, _, _, _, _) ->
        send self, {:leave, node.kind, Dict.get(node, :value)}
      end
    })

    assert_receive {:enter, :SelectionSet, nil}
  end
end
