use Mix.Config

config :ex_im, nodes: [:"a@127.0.0.1", :"b@127.0.0.1"]

import_config "#{Mix.env()}.exs"
