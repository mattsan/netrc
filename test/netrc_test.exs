defmodule NetrcTest do
  use ExUnit.Case
  doctest Netrc

  alias Netrc.Machine

  describe "lodad" do
    setup context do
      {:ok, io} = StringIO.open(context.source)
      [io: io]
    end

    @tag source: """
         # netrc includes a machine
         machine m1
           login l1
           password p1
         """
    test "includes a machine", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Machine{
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
               "m1" => %Machine{
                 login: "l1",
                 password: "p1"
               },
               "default" => %Machine{
                 login: "ld",
                 password: "pd"
               }
             }
    end

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
               "m1" => %Machine{
                 login: "l1",
                 password: "p1"
               },
               "m2" => %Machine{
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
               "m1" => %Machine{
                 login: "l1",
                 password: "p1"
               },
               "m2" => %Machine{
                 login: "l2",
                 password: "p2"
               },
               "default" => %Machine{
                 login: "ld",
                 password: "pd"
               }
             }
    end

    @tag source: """
         machine m1
           login l1
         """
    test "only login", %{io: io} do
      assert Netrc.load(io) == %{
               "m1" => %Machine{
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
               "m1" => %Machine{
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
               "default" => %Machine{
                 login: "ld",
                 password: "pd"
               }
             }
    end
  end

  describe "save" do
    setup do
      {:ok, io} = StringIO.open("")
      [io: io]
    end

    defp read_actual(io) do
      {:ok, {"", actual}} = StringIO.close(io)

      actual
    end

    test "saves a machine", %{io: io} do
      Netrc.save(io, %{
        "m1" => Machine.new("l1", "p1")
      })

      expected = """
      machine m1
        login l1
        password p1
      """

      assert read_actual(io) == expected
    end

    test "saves a machine with default", %{io: io} do
      Netrc.save(io, %{
        "default" => Machine.new("ld", "pd"),
        "m1" => Machine.new("l1", "p1")
      })

      expected = """
      machine m1
        login l1
        password p1
      default
        login ld
        password pd
      """

      assert read_actual(io) == expected
    end

    test "saves multiple machies", %{io: io} do
      Netrc.save(io, %{
        "m1" => Machine.new("l1", "p1"),
        "m2" => Machine.new("l2", "p2")
      })

      expected = """
      machine m1
        login l1
        password p1
      machine m2
        login l2
        password p2
      """

      assert read_actual(io) == expected
    end

    test "saves multiple machines with default", %{io: io} do
      Netrc.save(io, %{
        "default" => Machine.new("ld", "pd"),
        "m1" => Machine.new("l1", "p1"),
        "m2" => Machine.new("l2", "p2")
      })

      expected = """
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

      assert read_actual(io) == expected
    end

    test "saves only login", %{io: io} do
      Netrc.save(io, %{
        "m1" => Machine.new("l1")
      })

      expected = """
      machine m1
        login l1
      """

      assert read_actual(io) == expected
    end

    test "saves only password", %{io: io} do
      Netrc.save(io, %{
        "m1" => Machine.new(nil, "p1")
      })

      expected = """
      machine m1
        password p1
      """

      assert read_actual(io) == expected
    end

    test "saves only default", %{io: io} do
      Netrc.save(io, %{
        "default" => Machine.new("ld", "pd")
      })

      expected = """
      default
        login ld
        password pd
      """

      assert read_actual(io) == expected
    end
  end
end
