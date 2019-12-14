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

  @doc """
  Saves netrc configurations.

  - `io_or_filename` - an IO device or filename
  - `netrc` - netrc configurations

  ## Examples

  ### Saves to an IO device

      iex> StringIO.open("") |> elem(1) |> Netrc.save(%{
      ...>   "default" => %Netrc.Machine{login: "default@example.com", password: "default_pass"},
      ...>   "mach" => %Netrc.Machine{login: "foo@example.com", password: "foo_bar"}
      ...> }) |> StringIO.close()
      {:ok, {"", "machine mach\\n  login foo@example.com\\n  password foo_bar\\ndefault\\n  login default@example.com\\n  password default_pass\\n"}}

  ### Saves to a file

      Netrc.save("~/.netrc", %{
        "default" => %Netrc.Machine{login: "default@example.com", password: "default_pass"},
        "mach" => %Netrc.Machine{login: "foo@example.com", password: "foo_bar"}
      })

  """
  @doc since: "0.1.0"
  @spec save(pid() | String.t(), netrc()) :: pid() | String.t() | {:error, any()}
  def save(io_or_filename, netrc)

  def save(filename, netrc) when is_binary(filename) do
    filename
    |> Path.expand()
    |> File.open([:write], &save(&1, netrc))
    |> case do
      {:ok, _} -> filename
      error -> error
    end
  end

  def save(io, netrc) when is_pid(io) do
    {default, rest} = Map.pop(netrc, "default")

    rest
    |> Enum.each(fn {name, config} ->
      IO.puts(io, "machine #{name}")
      save_machine(io, config)
    end)

    if not is_nil(default) do
      IO.puts(io, "default")
      save_machine(io, default)
    end

    io
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

  @spec save_machine(pid(), Machine.t()) :: any()
  defp save_machine(io, %Machine{} = machine) do
    if not is_nil(machine.login), do: IO.puts(io, "  login #{machine.login}")
    if not is_nil(machine.password), do: IO.puts(io, "  password #{machine.password}")
  end
end
