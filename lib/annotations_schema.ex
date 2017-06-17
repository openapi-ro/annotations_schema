
defmodule Annotations.Repo do
  use Ecto.Repo, otp_app: :annotations_schema
end
defmodule Annotations.Schema.ContentString do
  use Ecto.Schema
  @schema_prefix "annotations"
  @primary_key {:md5, Ecto.UUID, []}
  schema "content_strings"  do
    #field :md5, :binary_id, primary_key: true
    field :sticky, :boolean, default: Application.get_env(:annotations_schema, :sticky, true)
    field :content, :string
    timestamps()
  end
end
defmodule Annotations.Schema.Annotation do
  use Ecto.Schema
  @schema_prefix "annotations"
  @primary_key false
  schema "annotations" do
    field :string_md5, :binary_id, primary_key: true
    field :f, :integer
    field :t, :integer
    field :tags, {:array, :string}
    field :info, :map
    timestamps()
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
    {:ok,md5}= Ecto.UUID.load :crypto.hash(:md5, str)
    on_conflict = Keyword.get(options, :on_conflict, :nothing)
    clean_annotations =  Keyword.get(options, :clean_annotations, true)
    import Ecto.Query
    multi=
      if clean_annotations do
        Multi.delete_all(Multi.new(), "delete_previous_annotations", from([a] in Schema.Annotation, where: a.string_md5 == ^md5 ))
      else
        Multi.new()
      end
    multi=
      multi
      |> Multi.insert( :string, %Schema.ContentString{md5: md5, content: str}, on_conflict: on_conflict )
    anns
      |>Enum.with_index()
      |> Enum.reduce(multi ,fn {ann, idx}, multi->
          multi
          |>Multi.insert("op#{idx}" , %Schema.Annotation{
            string_md5: md5,
            f: ann.from,
            t: ann.to,
            tags: Enum.map(ann.tags, &to_string/1),
            info: ann.info })
          end)
    |> Annotations.Repo.transaction(, timeout: :infinity)
  end
  def load( checksums, options ) do
    import Ecto.Query
    checksums=
      case checksums do
        checksum when is_bitstring(checksum) -> [checksum]
        _-> checksums
      end
      |> Enum.map(&(elem(Ecto.UUID.load(&1),1)))
    anns =
      Annotations.Repo.all(from([a] in Schema.Annotation,
        order_by: [a.string_md5, a.f],
        where: a.string_md5 in ^checksums
        ))
      |> Enum.group_by( fn sa -> sa.string_md5 end)
      |> Enum.map( fn {md5,schema_annotations} ->
          per_str=
            Enum.map(schema_annotations, fn sa ->
              %Annotations.Annotation{
                from: sa.f,
                to: sa.t,
                tags: sa.tags|> Enum.map(&String.to_atom/1),
                info:
                  if Keyword.get(options, :keys , :atoms) == :atoms do
                    OA.Map.atomize_keys(sa.info)
                  else
                    sa.info
                  end
              } end)
          {md5, per_str}
        end)
      |> Map.new()
    strings =
      Annotations.Repo.all(from([str] in Schema.ContentString, where: str.md5 in ^checksums))
      |> Enum.map(fn str->
        %Annotations.AnnotatedString{
          str: str.content,
          annotations: Map.get(anns, str.md5, []) }
      end)
  end
end
