defmodule ExIm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    nodes = Application.get_env(:ex_im, :nodes, :dynamic)

    env =
      case node() do
        :nonode@nohost ->
          :local

        _ ->
          :distributed
      end

    children = [
      {ExIm.Node, %{nodes: nodes, env: env}}
    ]

    opts = [strategy: :one_for_one, name: ExIm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
