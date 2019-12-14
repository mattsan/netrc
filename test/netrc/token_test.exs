defmodule Netrc.TokenTest do
  use ExUnit.Case
  doctest Netrc.Token

  setup context do
    case Map.get(context, :source) do
      nil ->
        :ok

      source ->
        {:ok, io} = StringIO.open(source)
        [io: io]
    end
  end

  describe "simple source" do
    @tag source: """
         machine foo
         login bar
         password baz
         """
    test "includes a machine", %{io: io} do
      tokens = io |> Netrc.Token.new() |> Enum.to_list()

      assert tokens == ~w(machine foo login bar password baz)
    end

    @tag source: """
         # this is a simple source with comments
         machine foo # this line is describing a machine
         login bar # this line is describing a login user
         password baz # this line is describing a login password
         # eof
         """
    test "includes a machine with comments", %{io: io} do
      tokens = io |> Netrc.Token.new() |> Enum.to_list()

      assert tokens == ~w(machine foo login bar password baz)
    end
  end

  describe "multiple section source" do
    @tag source: """
         machine foo
         login bar
         password baz

         machine hoge
         login fuga
         password uhyo
         """
    test "includes two machines", %{io: io} do
      tokens = io |> Netrc.Token.new() |> Enum.to_list()

      assert tokens ==
               ~w(machine foo login bar password baz machine hoge login fuga password uhyo)
    end

    @tag source: """
         # this is a simple source with comments
         # the first machine
         machine foo # this line is describing a machine
         login bar # this line is describing a login user
         password baz # this line is describing a login password

         # the second machine
         machine hoge
         login fuga
         password uhyo

         # the third machine
         # machine u
         # login ya
         # password ta
         """
    test "includes two machines with comments", %{io: io} do
      tokens = io |> Netrc.Token.new() |> Enum.to_list()

      assert tokens ==
               ~w(machine foo login bar password baz machine hoge login fuga password uhyo)
    end
  end
end
