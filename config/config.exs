use Mix.Config

config :ex_im, nodes: [:"a@127.0.0.1", :"b@127.0.0.1"]
config :ex_im, backend: ExIm.Storage.Dets
config :ex_im, tables: [:test_table]

import_config "#{Mix.env()}.exs"
