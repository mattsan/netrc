defmodule Netrc.Token do
  @moduledoc """
  A module of netrc tokens.

  A token implements the `Enumerable` protocol.

  ## Examples

  ### Reads from netrc file

      "~/.netrc"
      |> Path.expand()
      |> File.open!()
      |> Netrc.Token.new()
      |> Enum.to_list()

  ### Reads from a string

      iex> StringIO.open(~S(
      ...> machine foo@example.com
      ...> login username
      ...> password Passw0rd
      ...> )) |> elem(1) |> Netrc.Token.new() |> Enum.to_list()
      ["machine", "foo@example.com", "login", "username", "password", "Passw0rd"]
  """
  @moduledoc since: "0.1.0"

  defstruct [:io, tokens: []]

  alias Netrc.Token

  @type t :: %__MODULE__{
    io: pid(),
    tokens: [String.t()] | :eof
  }

  @doc """
  Creates a Token context.

  - `io` - an IO device
  """
  @doc since: "0.1.0"
  @spec new(pid()) :: t()
  def new(io) do
    %Token{io: io, tokens: []}
  end

  @doc """
  Gets a next token.

  - `token` - Token context

  This function may be returns:

  - `{value, token}` - a next token value `value` and next context `token`
  - `{nil, token}` - no next token value
  """
  @doc since: "0.1.0"
  @spec next(t()) :: {String.t() | nil, t()}
  def next(%Token{} = token) do
    next_token = read(token)

    case next_token.tokens do
      [value | next_tokens] ->
        {value, %{token | tokens: next_tokens}}

      :eof ->
        {:nil, next_token}
    end
  end

  @spec read(t()) :: t()
  defp read(token)

  defp read(%Token{io: io, tokens: []} = token) do
    case IO.read(io, :line) do
      :eof ->
        %{token | tokens: :eof}

      {:error, _} = error ->
        %{token | tokens: error}

      line ->
        tokens =
          line
          |> String.split("#")
          |> hd()
          |> String.split(~r/\s+/, trim: true)

        case tokens do
          [] -> read(token)
          _ -> %{token | tokens: tokens}
        end
    end
  end

  defp read(%Token{} = token), do: token

  defimpl Enumerable do
    def count(_token) do
      {:error, __MODULE__}
    end

    def member?(_token, _element) do
      {:error, __MODULE__}
    end

    def reduce(_token, {:halt, acc}, _fun) do
      {:halted, acc}
    end

    def reduce(token, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(token, &1, fun)}
    end

    def reduce(%Token{tokens: :eof}, {:cont, acc}, _fun) do
      {:done, acc}
    end

    def reduce(token, {:cont, acc}, fun) do
      case Token.next(token) do
        {nil, _} ->
          {:done, acc}

        {value, next_token} ->
          reduce(next_token, fun.(value, acc), fun)
      end
    end

    def slice(_token) do
      {:error, __MODULE__}
    end
  end
end
