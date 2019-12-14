defmodule NetrcTest do
  use ExUnit.Case
  doctest Netrc

  setup context do
    case Map.get(context, :source) do
      nil ->
        :ok

      source ->
        {:ok, io} = StringIO.open(source)
        [io: io]
    end
  end

  describe "single" do
    @tag source: """
         # netrc includes a machine
         machine m1
           login l1
           password p1
         """
    test "includes a machine", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Netrc.Machine{
                 login: "l1",
                 password: "p1"
               }
             }
    end

    @tag source: """
         # netrc includes a machine
         machine m1
           login l1
           password p1

         default
           login ld
           password pd
         """
    test "includes a machine with default", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Netrc.Machine{
                 login: "l1",
                 password: "p1"
               },
               "default" => %Netrc.Machine{
                 login: "ld",
                 password: "pd"
               }
             }
    end
  end

  describe "multiple" do
    @tag source: """
         # netrc includes multiple machines
         machine m1
           login l1
           password p1

         machine m2
           login l2
           password p2
         """
    test "includes multiple machies", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Netrc.Machine{
                 login: "l1",
                 password: "p1"
               },
               "m2" => %Netrc.Machine{
                 login: "l2",
                 password: "p2"
               }
             }
    end

    @tag source: """
         machine m1
           login l1
           password p1

         machine m2
           login l2
           password p2

         default
           login ld
           password pd
         """
    test "includes multiple machines with default", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Netrc.Machine{
                 login: "l1",
                 password: "p1"
               },
               "m2" => %Netrc.Machine{
                 login: "l2",
                 password: "p2"
               },
               "default" => %Netrc.Machine{
                 login: "ld",
                 password: "pd"
               }
             }
    end
  end

  describe "only" do
    @tag source: """
         machine m1
           login l1
         """
    test "only login", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Netrc.Machine{
                 login: "l1"
               }
             }
    end

    @tag source: """
         machine m1
           password p1
         """
    test "only password", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Netrc.Machine{
                 password: "p1"
               }
             }
    end

    @tag source: """
         default
           login ld
           password pd
         """
    test "only default", %{io: io} do
      assert Netrc.load(io) == %{
               "default" => %Netrc.Machine{
                 login: "ld",
                 password: "pd"
               }
             }
    end
  end
end
