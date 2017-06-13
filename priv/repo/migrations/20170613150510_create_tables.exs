defmodule Annotations.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:content_strings, prefix: :annotations, primary_key: false) do
      add :md5, :uuid, primary_key: true #size: 16
      add :sticky, :boolean, default: Application.get_env(:annotations_schema, :sticky, true)
      add :content, :text
      timestamps()
    end
    create table(:annotations, prefix: :annotations, primary_key: false) do
      add :string_md5, :uuid #size: 16
      add :f, :integer
      add :t, :integer
      add :tags, :array
      add :info, :map
      timestamps()
    end
    create index(:annotations, [:string_md5, :f, :t], prefix: :annotations)
  end
end
