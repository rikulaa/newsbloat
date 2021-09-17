defmodule Newsbloat.RSS do
  @moduledoc """
  The RSS context.
  """

  alias HTTPoison
  import Ecto.Query, warn: false
  alias Newsbloat.Repo

  alias Newsbloat.RSS.Feed
  alias Newsbloat.RSS.Item
  alias Newsbloat.RSS.Tag

  @doc """
  Returns the list of feeds.

  ## Examples

      iex> list_feeds()
      [%Feed{}, ...]

  """
  def list_feeds do
    tags_query = from(t in Tag, select: t.title)
    Repo.all(from f in Feed, preload: [tags: ^tags_query])
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
  def get_feed!(id) do
    tags_query = from(t in Tag, select: t.title)
    Repo.one(from feed in Feed, where: feed.id == ^id, preload: [tags: ^tags_query])
  end

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

    {:ok, items } = fetch_feed_items(feed)
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
    |> Repo.preload([tags: from(t in Tag, select: t.title)])
    |> Enum.map(&Item.with_safe_content_and_desc/1)
    
  end

  def fetch_feed_items(%Feed{} = feed) do
    IO.puts(feed.title)
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(feed.url)

    parsed_body = body
    |> Quinn.parse()

    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive()

    all_parsed_rss_categories = parsed_body
                           |> Quinn.find(:category)
                           |> Enum.reduce([], fn cur, acc -> acc ++ cur.value end)
    all_parsed_atom_categories = parsed_body
                             |> Quinn.find(:category)
                             |> Enum.reduce([], fn cur, acc -> acc ++ [cur.attr[:term]] end)
    all_parsed_tags_flat = all_parsed_rss_categories ++ all_parsed_atom_categories |> Enum.uniq()

    # Store every found tag in the database.
    # In case the tag already exists, don't do anything to it
    all_parsed_tags = all_parsed_tags_flat
                      |>  Enum.reduce([], fn value, acc -> acc ++ [ %{ "title": value, "inserted_at": now, "updated_at": now} ] end)
    Repo.insert_all(Tag, all_parsed_tags, on_conflict: :nothing)
    # Fetch tags from db as the 'insert_all' on_conflict: :nothing, does not return the list of entries
    all_tags = Repo.all(from t in Tag, where: t.title in ^all_parsed_tags_flat)

    # Tag the feed itself
    rss_feed_categories = parsed_body |> Quinn.find(:channel) |> List.first() |> (fn first -> if first != nil, do: first, else: %{} end).() |> Map.get(:value, [ %{ name: nil } ]) |> Enum.filter(fn x -> x.name == :category end) |> Enum.reduce([], fn cur, acc -> acc ++ cur.value end)
    atom_feed_categories =  parsed_body |> Quinn.find(:feed) |> List.first() |> (fn first -> if first != nil, do: first, else: %{} end).() |> Map.get(:value, [ %{ name: nil } ]) |> Enum.filter(fn x -> x.name == :category end) |> Enum.reduce([], fn cur, acc -> acc ++ [cur.attr[:term]] end)
    feed_categories = rss_feed_categories ++ atom_feed_categories

    feed = Repo.preload(feed, [:tags])
    feed
    |> Feed.changeset(Map.from_struct(feed))
    |> Ecto.Changeset.put_assoc(:tags, all_tags |> Enum.filter(fn t -> Enum.member?(feed_categories, t.title) end) |> Enum.concat(feed.tags) )
    |> Repo.update()


    # TODO: More robust checks and parsing for atom/rss items
    rss_items = parsed_body
                |> Quinn.find(:item)
                |> Enum.reverse()
                |> Enum.map(
                  fn (item) -> 
                    %{ value: value } = item

                    content = get_value_from_map_list_by_key(value, :"content:encoded") || get_value_from_map_list_by_key(value, :content)

                    tag_titles = item |> Quinn.find(:category) |> Enum.reduce([], fn cur, acc -> acc ++ cur.value end)

                    %Item{} 
                    |> Item.changeset(%{
                    # published_at: Timex.parse!(get_value_from_map_list_by_key(value, :pubDate), "{RFC822z}"),
                    # TODO: fix the date parsing
                      published_at: now, 
                      guid: get_value_from_map_list_by_key(value, :guid),
                      title: get_value_from_map_list_by_key(value, :title),
                      link: get_value_from_map_list_by_key(value, :link),
                      description: get_value_from_map_list_by_key(value, :description),
                      content: content,
                      feed_id: feed.id,
                    })
                    |> Ecto.Changeset.put_change(:feed_id, feed.id)
                    |> Ecto.Changeset.put_assoc(:tags, all_tags |> Enum.filter(fn t -> Enum.member?(tag_titles, t.title) end))
                  end)

    atom_items = parsed_body
                 |> Quinn.find(:entry)
                 |> Enum.reverse()
                 |> Enum.map(
                   fn (item) -> 
                     %{ value: value } = item

                     content = get_value_from_map_list_by_key(value, :content) || get_value_from_map_list_by_key(value, :summary)
                     tag_titles = item |> Quinn.find(:category) |> Enum.reduce([], fn cur, acc -> acc ++ [cur.attr[:term]] end)

                     %Item{} 
                     |> Item.changeset(%{
                      # published_at: Timex.parse!(get_value_from_map_list_by_key(value, :pubDate), "{RFC822z}"),
                      # TODO: fix the date parsing
                       published_at: now, 
                       guid: get_value_from_map_list_by_key(value, :id),
                       title: get_value_from_map_list_by_key(value, :title),
                       link: get_attr_value_from_map_list_by_key(value, :link, :href),
                       description: get_value_from_map_list_by_key(value, :summary),
                       content: content,
                       feed_id: feed.id,
                     })
                     |> Ecto.Changeset.put_change(:feed_id, feed.id)
                     |> Ecto.Changeset.put_assoc(:tags, all_tags |> Enum.filter(fn t -> Enum.member?(tag_titles, t.title) end))
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
    update_item(item, %{ "is_read": true })
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

    # TODO: Should use transaction for each individual feed (not for all). Can cause timeouts like this.
    Repo.transaction(fn() ->
      query
      |> Repo.stream([{ :max_rows, max_rows }])
      |> Stream.chunk_every(max_rows)
      |> Enum.each(fn batch ->
        batch |> Enum.each(fn feed -> fetch_feed_items(feed) end)
      end)
    end, timeout: 1000 * 60) # 1 minute
  end


end
