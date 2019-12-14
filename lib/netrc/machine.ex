defmodule Netrc.Machine do
  @moduledoc """
  A struct of netrc machine information.
  """
  @moduledoc since: "0.1.0"

  defstruct [:login, :password]

  alias Netrc.Machine

  @type t :: %__MODULE__{
    login: String.t() | nil,
    password: String.t() | nil
  }


  @doc """
  Returns a new machine struct.
  """
  @spec new(String.t() | nil, String.t() | nil) :: t()
  def new(login \\ nil, password \\ nil) do
    %Machine{login: login, password: password}
  end
end
