defmodule Annotations.Repo.Migrations.CreateSchema do
  use Ecto.Migration

  def up do
    execute "Create schema annotations;"
  end
  def down do
    execute "DROP SCHEMA annotations;"
  end
end
