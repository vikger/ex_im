defmodule ExIm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    nodes = Application.get_env(:ex_im, :nodes, :dynamic)
    children =
      case node() do
        :nonode@nohost ->
          []
        _ ->
          [
            {ExIm.Node, nodes}
          ]
      end

    opts = [strategy: :one_for_one, name: ExIm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
