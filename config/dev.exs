
use Mix.Config
config :annotations_schema, Annotations.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "moapi_dev",
  hostname: "localhost",
  pool_size: 10
