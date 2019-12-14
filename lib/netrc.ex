defmodule Netrc do
  @moduledoc """
  A module to manipulate netrc.
  """
  @moduledoc since: "0.1.0"

  alias Netrc.Machine

  @type netrc :: %{String.t() => Machine.t()}

  @doc """
  Loads netrc configurations.

  - `io_or_filename` - an IO device or filename

  ## Examples

  ### Loads from an IO device

      iex> StringIO.open(~S(
      ...>   machine mach 
      ...>     login foo@example.com
      ...>     password foo_bar
      ...>
      ...>   default
      ...>     login default@example.com
      ...>     password default_pass
      ...>   )) |> elem(1) |> Netrc.load()
      %{
        "mach" => %Netrc.Machine{
          login: "foo@example.com",
          password: "foo_bar"
        },
        "default" => %Netrc.Machine{
          login: "default@example.com",
          password: "default_pass"
        }
      }

  ### Loads from a file

      Netrc.load("~/.netrc")
  """
  @doc since: "0.1.0"
  @spec load(pid() | String.t()) :: netrc()
  def load(io_or_filename)

  def load(filename) when is_binary(filename) do
    {:ok, netrc} =
      filename
      |> Path.expand()
      |> File.open(&load/1)

    netrc
  end

  def load(io) when is_pid(io) do
    io
    |> Netrc.Token.new()
    |> Enum.to_list()
    |> parse()
  end

  @spec parse([String.t()]) :: netrc()
  defp parse(tokens), do: parse(tokens, "", %{})

  @spec parse([String.t()], String.t(), netrc()) :: netrc()
  defp parse(tokens, machine, acc)

  defp parse([], _, acc), do: acc

  defp parse(["default" | tokens], _, acc) do
    new_acc = Map.put_new(acc, "default", Machine.new())
    parse(tokens, "default", new_acc)
  end

  defp parse(["machine", name | tokens], _, acc) do
    new_acc = Map.put_new(acc, name, Machine.new())
    parse(tokens, name, new_acc)
  end

  defp parse(["login", name | tokens], machine, acc) do
    new_acc = Map.update!(acc, machine, &Map.put(&1, :login, name))
    parse(tokens, machine, new_acc)
  end

  defp parse(["password", name | tokens], machine, acc) do
    new_acc = Map.update!(acc, machine, &Map.put(&1, :password, name))
    parse(tokens, machine, new_acc)
  end
end
