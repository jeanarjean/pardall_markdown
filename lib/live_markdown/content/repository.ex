defmodule LiveMarkdown.Content.Repository do
  alias LiveMarkdown.{Post, Link}
  alias LiveMarkdown.Content.Cache
  alias LiveMarkdownWeb.Endpoint
  import LiveMarkdown.Content.Repository.Filters
  require Logger

  def init do
    Cache.delete_all()
  end

  #
  # CRUD interface
  #

  def get_all_posts do
    Cache.get_all_posts()
  end

  def get_all_taxonomies do
    Cache.get_all_taxonomies()
  end

  def get_taxonomy_tree(sort_by \\ :title) do
    Cache.get_taxonomy_tree(sort_by)
  end

  def get_content_tree(sort_by \\ :title) do
    Cache.get_content_tree(sort_by)
  end

  def get_all_published do
    get_all_posts()
    |> filter_by_is_published()
    |> sort_by_published_date()
  end

  def get_by_slug(slug), do: Cache.get_by_slug(slug)

  def get_by_slug!(slug) do
    get_by_slug(slug) || raise LiveMarkdown.NotFoundError, "Page not found: #{slug}"
  end

  def push_post(path, %{slug: slug} = attrs, content, _type \\ :post) do
    model = get_by_slug(slug) || %Post{}

    model
    |> Post.changeset(%{
      type: get_post_type_from_taxonomies(attrs.categories),
      file_path: path,
      title: attrs.title,
      content: content,
      slug: attrs.slug,
      date: attrs.date,
      summary: Map.get(attrs, :summary, nil),
      is_published: Map.get(attrs, :published, false),
      # for now, when a post is pushed to the repository, only "categories" are known
      taxonomies: attrs.categories,
      metadata: attrs |> remove_default_attributes()
    })
    |> Ecto.Changeset.apply_changes()
    |> save_post()
  end

  def delete_path(path) do
    case Cache.delete_path(path) do
      [_p | _] = posts ->
        Endpoint.broadcast!("content", "post_events", posts)

        for {slug, :deleted} <- posts do
          Endpoint.broadcast!("post_" <> slug, "post_deleted", true)
        end

      _ ->
        []
    end
  end

  def rebuild_indexes! do
    Cache.build_content_tree()
    # 2. find and save post siblings
  end

  #
  # Data helpers
  #

  # No taxonomy or a contains the root taxonomy: it's a page
  defp get_post_type_from_taxonomies([]), do: :page
  defp get_post_type_from_taxonomies([%{slug: "/"}]), do: :page
  defp get_post_type_from_taxonomies(_), do: :post

  defp save_post(%Post{id: nil, file_path: path} = model) do
    model = %{model | id: get_path_id(path)}
    Cache.save_post(model)
  end

  defp save_post(%Post{} = model), do: Cache.save_post(model)

  defp save_content_and_broadcast!(%Post{id: nil, file_path: path} = model) do
    model = %{model | id: get_path_id(path)}
    Cache.save_post(model)
    Endpoint.broadcast!("content", "post_created", model)
  end

  defp save_content_and_broadcast!(%Post{slug: slug} = model) do
    Cache.save_post(model)
    Endpoint.broadcast!("content", "post_updated", model)
    Endpoint.broadcast!("post_" <> slug, "post_updated", model)
  end

  defp get_path_id(path) do
    :crypto.hash(:sha, path) |> Base.encode16() |> String.downcase()
  end

  defp remove_default_attributes(attrs) do
    attrs
    |> Map.drop([:title, :slug, :date, :summary, :published, :categories])
  end
end
