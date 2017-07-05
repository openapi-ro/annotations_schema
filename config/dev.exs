
use Mix.Config
config :annotations_schema, Annotations.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system , "DB_URL"},
  pool_size: 10
