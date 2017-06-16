
defmodule Annotations.Repo do
  use Ecto.Repo, otp_app: :annotations_schema
end
defmodule Annotations.Schema.ContentStrings do
  use Ecto.Schema
  @schema_prefix "annotations"
  @primary_key {:md5, Ecto.UUID, []}
  schema "content_strings"  do
    #field :md5, :binary_id, primary_key: true
    field :sticky, :boolean, default: Application.get_env(:annotations_schema, :sticky, true)
    field :content, :string
    timestamps
  end
end
defmodule Annotations.Schema.Annotations do
  use Ecto.Schema
  @schema_prefix "annotations"
  @primary_key false
  schema "annotations" do
    field :string_md5, :binary_id, primary_key: true
    field :f, :integer
    field :t, :integer
    field :tags, {:array, :string}
    field :info, :map
    timestamps
  end
end

defmodule Annotations.Schema do
  use Application
   def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      worker(Annotations.Repo, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Annotations.Schema.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  @moduledoc """
  Documentation for Annotations.Schema.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Annotations.Schema.hello
      :world

  """

  alias Annotations.AnnotatedString
  alias Annotations.Schema
  alias Ecto.Multi
  @doc """
    Saves the given `AnnotatedString` to the database
    Accepted options are:

    * `:on_conflict`, which can have some value as specified for the corresponding option in `&Ecto.Repo.insert/2`
    the default is `[on_conflict: :nothing]`
    * `:clean_annotations`, `{true|false}` , specifies if all the annotations should be
    removed from the database before attempting to save the set from the `AnnotatedString`

    The `&save/2` function runs within a single transaction.
  """
  def save(%AnnotatedString{str: str, annotations: anns}, options) do
    {:ok,md5}= Ecto.UUID.load :crypto.hahs(:md5, str)
    on_conflict = Keyword.get(options, :on_conflict, :nothing)
    clean_annotations =  Keyword.get(options, :clean_annotations, true)
    import Ecto.Query
    multi=
      if clean_annotations do
        Multi.delete_all(Multi.new(), "delete_previous_annotations", from([a] in Schema.Annotations, where: a.string_md5 == ^md5 ))
      else
        Multi.new()
      end
    multi=
      multi
      |> Multi.insert( :string, %Schema.ContentStrings{md5: md5, content: str}, on_conflict: on_conflict )
    anns
      |>Enum.with_index()
      |> Enum.reduce(multi ,fn {ann, idx}, multi->
          multi
          |>Multi.insert("op#{idx}" , %Schema.Annotations{
            string_md5: md5,
            f: ann.from,
            t: ann.to,
            tags: Enum.map(ann.tags, &to_string/1),
            info: ann.info })
          end)
    |> Annotations.Repo.transaction()
  end
end
