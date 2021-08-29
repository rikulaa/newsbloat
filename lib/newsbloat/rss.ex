defmodule Newsbloat.RSS do
  @moduledoc """
  The RSS context.
  """

  alias HTTPoison
  import Ecto.Query, warn: false
  alias Newsbloat.Repo

  alias Newsbloat.RSS.Feed
  alias Newsbloat.RSS.Item

  @doc """
  Returns the list of feeds.

  ## Examples

      iex> list_feeds()
      [%Feed{}, ...]

  """
  def list_feeds do
    Repo.all(Feed)
  end

  @doc """
  Gets a single feed.

  Raises `Ecto.NoResultsError` if the Feed does not exist.

  ## Examples

      iex> get_feed!(123)
      %Feed{}

      iex> get_feed!(456)
      ** (Ecto.NoResultsError)

  """
  def get_feed!(id), do: Repo.get!(Feed, id)

  @doc """
  Creates a feed.

  ## Examples

      iex> create_feed(%{field: value})
      {:ok, %Feed{}}

      iex> create_feed(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feed(attrs \\ %{}) do
    {:ok, feed} = %Feed{}
    |> Feed.changeset(attrs)
    |> Repo.insert()

    {:ok, items } = Newsbloat.RSS.fetch_feed_items(feed)
    IO.puts("SHOULD HAVE FETCHTED")
    IO.puts(Enum.count(items))
    {:ok, feed}
  end

  @doc """
  Updates a feed.

  ## Examples

      iex> update_feed(feed, %{field: new_value})
      {:ok, %Feed{}}

      iex> update_feed(feed, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feed(%Feed{} = feed, attrs) do
    feed
    |> Feed.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feed.

  ## Examples

      iex> delete_feed(feed)
      {:ok, %Feed{}}

      iex> delete_feed(feed)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feed(%Feed{} = feed) do
    Repo.delete(feed)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feed changes.

  ## Examples

      iex> change_feed(feed)
      %Ecto.Changeset{data: %Feed{}}

  """
  def change_feed(%Feed{} = feed, attrs \\ %{}) do
    Feed.changeset(feed, attrs)
  end

  def mark_all_feed_items_as_read(%Feed{} = feed) do
    query = from item in Item,
      where: item.feed_id == ^feed.id, 
      update: [set: [is_read: true]]

    {updates, _ } = query
    |> Repo.update_all([])

    {:ok, feed}
  end


  def get_value_from_map_list_by_key(map_list, key) do
    %{ value: value } = map_list
                        |> Enum.find(%{ value: []}, fn i -> i.name === key end)
    value
    |> List.first()
  end
  def get_attr_value_from_map_list_by_key(map_list, key, attr) do
    %{ attr: attr_list } = map_list
                        |> Enum.find(%{ attr: []}, fn i -> i.name === key end)
    attr_list[attr]
  end

  def get_feed_item(%Feed{} = feed, item_id) do
    query = from item in Item, where: item.feed_id == ^feed.id and item.id == ^item_id, order_by: [desc: item.id]
    Repo.one(query)
    |> Item.with_safe_content_and_desc()
  end
  def get_feed_items(%Feed{} = feed) do
    query = from item in Item, where: item.feed_id == ^feed.id, order_by: [desc: item.id]
    Repo.all(query)
    |> Enum.map(&Item.with_safe_content_and_desc/1)
    
  end

  def fetch_feed_items(%Feed{} = feed) do
    IO.puts(feed.title)
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(feed.url)

    parsed_body = body
    |> Quinn.parse()

    rss_items = parsed_body
    |> Quinn.find(:item)
    |> Enum.reverse()
    |> Enum.map(
      fn (item) -> 
        %{ value: value } = item

        content = Newsbloat.RSS.get_value_from_map_list_by_key(value, :"content:encoded") || Newsbloat.RSS.get_value_from_map_list_by_key(value, :content)

        # TODO: fix the date parsing
        now = DateTime.now("Etc/UTC")
              |> (fn {:ok, date} -> date end).()
              |> DateTime.truncate(:second)

        %Item{} 
        |> Item.changeset(%{
            # published_at: Timex.parse!(Newsbloat.RSS.get_value_from_map_list_by_key(value, :pubDate), "{RFC822z}"),
          published_at: now, 
          guid: Newsbloat.RSS.get_value_from_map_list_by_key(value, :guid),
          title: Newsbloat.RSS.get_value_from_map_list_by_key(value, :title),
          link: Newsbloat.RSS.get_value_from_map_list_by_key(value, :link),
          description: Newsbloat.RSS.get_value_from_map_list_by_key(value, :description),
          content: content,
          feed_id: feed.id,
        })
        |>  Ecto.Changeset.put_change(:feed_id, feed.id)
    end)

    atom_items = parsed_body
                 |> Quinn.find(:entry)
                 |> Enum.reverse()
                 |> Enum.map(
                   fn (item) -> 
                     %{ value: value } = item

                     content = Newsbloat.RSS.get_value_from_map_list_by_key(value, :content) || Newsbloat.RSS.get_value_from_map_list_by_key(value, :summary)

                    # TODO: fix the date parsing
                     now = DateTime.now("Etc/UTC")
                           |> (fn {:ok, date} -> date end).()
                           |> DateTime.truncate(:second)

                     %Item{} 
                     |> Item.changeset(%{
                      # published_at: Timex.parse!(Newsbloat.RSS.get_value_from_map_list_by_key(value, :pubDate), "{RFC822z}"),
                       published_at: now, 
                       guid: Newsbloat.RSS.get_value_from_map_list_by_key(value, :id),
                       title: Newsbloat.RSS.get_value_from_map_list_by_key(value, :title),
                       link: Newsbloat.RSS.get_attr_value_from_map_list_by_key(value, :link, :href),
                       description: Newsbloat.RSS.get_value_from_map_list_by_key(value, :summary),
                       content: content,
                       feed_id: feed.id,
                     })
                     |>  Ecto.Changeset.put_change(:feed_id, feed.id)
                   end)

    # Filter out any existing items we have
    existing_ids = rss_items ++ atom_items
              |> Enum.map(fn (item) -> Ecto.Changeset.get_field(item, :guid) end)
              |> (fn item_ids -> Repo.all(from item in Item, where: item.guid in ^item_ids, select: %{guid: item.guid}) end).()
              |> Enum.map(fn (entry) -> entry.guid end)

    rss_items ++ atom_items
    |> Enum.filter(fn (item) -> Ecto.Changeset.get_field(item, :guid) not in existing_ids end)
    |> Enum.with_index()
    |> Enum.reduce(
      Ecto.Multi.new(),
      fn ({ changeset, idx }), multi ->
        Ecto.Multi.insert(multi, Integer.to_string(idx), changeset)
      end
    )
    |> Repo.transaction()
  end


  def update_item(%Item{} = item, attrs) do
    item 
    |> Item.changeset(attrs)
    |> Repo.update
  end

  def mark_item_as_read(%Item{} = item) do
    Newsbloat.RSS.update_item(item, %{ "is_read": true })
  end

  def get_feed_items_unread_count!(feed) do
    [count] = Repo.all(
      from i in Item, where: [feed_id: ^feed.id, is_read: false], select: count(i.id)
    )
    count
  end

  def fetch_feed_items_for_all_feeds() do
    query = from feed in Feed
    max_rows = 10

    Repo.transaction(fn() ->
      query
      |> Repo.stream([{ :max_rows, max_rows }])
      |> Stream.chunk_every(max_rows)
      |> Enum.each(fn batch ->
        batch |> Enum.each(fn feed -> Newsbloat.RSS.fetch_feed_items(feed) end)
      end)
    end)
  end


end
