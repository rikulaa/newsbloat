defmodule Newsbloat.RSS do
  @moduledoc """
  The RSS context.
  """

  require Logger
  alias HTTPoison
  import Ecto.Query, warn: false
  alias Newsbloat.Repo
  alias Newsbloat.Cache

  alias Newsbloat.RSS.Parser

  alias Newsbloat.RSS.Feed
  alias Newsbloat.RSS.Item
  alias Newsbloat.RSS.Tag

  def build_query(queryable, opts \\ []) do
    # TODO: automatic query builder from keys (or maybe explicitely define them in item.ex)
    # keys =
    #   struct(queryable)
    #   |> Map.keys()
    #   |> Enum.map(fn k -> to_string(k) end)
    #   |> Enum.filter(fn key -> !String.starts_with?(key, "__") end)
    keys = queryable.filterable_keys
    # Pick only keys which are allowed
    allowed_opts = opts |> Enum.filter(fn {k, _} -> Enum.member?(keys, k) end)

    parse_actual_value = fn s -> String.replace(s, "lk__", "") end

    Enum.reduce(allowed_opts, queryable, fn
      {:order_by, "asc__" <> value}, query ->
        actual_value = parse_actual_value.(value) |> String.to_existing_atom()
        order_by(query, [q], asc: field(q, ^actual_value))

      {:order_by, "desc__" <> value}, query ->
        actual_value = parse_actual_value.(value) |> String.to_existing_atom()
        order_by(query, [q], desc: field(q, ^actual_value))

      # ilike
      {k, "lk__" <> value}, query ->
        v = value |> String.replace("lk__", "")
        actual_value = "%" <> v <> "%"
        where(query, [q], ilike(field(q, ^k), ^actual_value))

      # less than
      {k, "lt__" <> value}, query ->
        where(query, [q], field(q, ^k) < ^parse_actual_value.(value))

      # Greater than
      {k, "gt__" <> value}, query ->
        where(query, [q], field(q, ^k) > ^parse_actual_value.(value))

      # Equals
      {k, value}, query ->
        where(query, ^[{k, value}])
    end)
  end

  @doc """
  Returns the list of feeds.

  ## Examples

      iex> list_feeds()
      [%Feed{}, ...]

  """
  def list_feeds() do
    query = from(f in Feed, preload: [:tags])

    query
    |> Repo.paginate()
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
    Repo.one(from feed in Feed, where: feed.id == ^id, preload: [:tags])
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
    case(
      %Feed{}
      |> Feed.changeset(attrs)
      |> Repo.insert()
    ) do
      {:ok, feed} ->
        {:ok, _} = fetch_feed_items(feed)
        {:ok, feed}

      err ->
        err
    end
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
    Item
    |> join(:inner, [item], tag in assoc(item, :tags))
    |> where([item, tag], item.feed_id == 10)
    |> select([_, tags], tags)
    |> Repo.delete_all()

    Item
    |> where([item], item.feed_id == ^feed.id)

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
    query =
      from item in Item,
        where: item.feed_id == ^feed.id,
        update: [set: [is_read: true]]

    query
    |> Repo.update_all([])

    {:ok, feed}
  end

  def mark_feed_items_as_read(%Feed{} = feed, items \\ []) do
    ids = items |> Enum.map(fn item -> item.id end)

    query =
      from item in Item,
        where: item.id in ^ids,
        update: [set: [is_read: true]]

    query
    |> Repo.update_all([])

    {:ok, feed}
  end

  def clean_orphaned_tags() do
    orphaned_tags_query =
      Tag
      |> join(:left, [tag], ft in fragment("feed_tags"), on: ft.tag_id == tag.id)
      |> join(:left, [tag, ft, it], it in fragment("item_tags"), on: it.tag_id == tag.id)
      |> where([tag, ft, it], is_nil(ft.tag_id) and is_nil(it.tag_id))
      |> select([tag, ft, it], tag.id)

    {entries_deleted, _} =
      Tag
      |> where([tag], tag.id in subquery(orphaned_tags_query))
      |> Repo.delete_all()

    {:ok, entries_deleted}
  end

  def get_value_from_map_list_by_key(map_list, key) do
    %{value: value} =
      map_list
      |> Enum.find(%{value: []}, fn i -> i.name === key end)

    value
    |> List.first()
  end

  def get_attr_value_from_map_list_by_key(map_list, key, attr) do
    %{attr: attr_list} =
      map_list
      |> Enum.find(%{attr: []}, fn i -> i.name === key end)

    attr_list[attr]
  end

  def get_feed_item(%Feed{} = feed, item_id) do
    cache_id = "feed_item:" <> to_string(feed.id) <> to_string(item_id)

    case Cache.get(cache_id) do
      {:error, _} ->
        query =
          from(
            item in Item,
            where: item.feed_id == ^feed.id and item.id == ^item_id,
            order_by: [desc: item.id],
            preload: [:tags]
          )

        item =
          Repo.one(query)
          |> Item.with_safe_content_and_desc()

        # Cache results
        # TODO: invalidate cache if item is updated (e.g mark as read)
        Cache.insert(cache_id, item, 60 * 60)
        item

      {:ok, res} ->
        res
    end
  end

  def list_feed_items(%Feed{} = feed, page, opts \\ []) do
    query =
      from(
        item in build_query(Item, opts),
        where: item.feed_id == ^feed.id,
        order_by: [desc: item.id],
        preload: [:tags]
      )

    page = query |> Repo.paginate(page: page)

    # Apparently, if we try to enumerate the 'page' directly, it will provide us the 'page.entries'.
    # Is this some 'collectables' magic?
    page
    |> Map.put(:entries, Enum.map(page.entries, &Item.with_safe_content_and_desc/1))
  end

  @doc """
  Returns the list of items which match given search parameter.

  ## Examples

      iex> list_feeds()
      [%Feed{}, ...]

  """
  def search_items(q \\ "") do
    words = Regex.scan(~r/[a-zA-Z0-9]+/, q)
    keyword_str = words |> Enum.join(" ")

    ts_query_string =
      words
      # 'fuzzy' search for every word
      |> Enum.map(fn [part] -> part <> ":*" end)
      |> Enum.join(" & ")

    if String.length(ts_query_string) > 0 do
      # TODO: or select tags with equal match
      case Cache.get(ts_query_string) do
        # No cache entry found, fetch results from db
        {:error, _} ->
          res =
            Item
            |> distinct(true)
            |> join(:left, [item], tag in assoc(item, :tags))
            |> where(
              [item, tags],
              fragment("_search_tsv @@ to_tsquery(?)", ^ts_query_string)
            )
            |> or_where(
              [_item, tags],
              tags.title in [^keyword_str]
            )
            |> preload([:feed])
            |> Repo.all()

          # Cache results
          Cache.insert(ts_query_string, res, 2)
          res

        {:ok, res} ->
          res
      end
    else
      []
    end
  end

  def create_tags_from_list(tag_list) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive()

    tags =
      tag_list
      |> Enum.map(fn tag -> %{title: tag, inserted_at: now, updated_at: now} end)

    Repo.insert_all(Tag, tags, on_conflict: :nothing)
  end

  def fetch_feed_body_by_url(url) do
    case HTTPoison.get(String.trim(url)) do
      {:ok, %HTTPoison.Response{body: body}} ->
        body
        |> Quinn.parse()

      # If there is error just return empty array
      {:error, _} ->
        []
    end
  end

  def maybe_populate_feed_title_and_description(%{} = feed) do
    body = fetch_feed_body_by_url(feed.url)

    is_rss = body |> Quinn.find(:rss) |> length() > 0

    if is_rss do
      # rss feed
      rss_title = body |> Quinn.find(:title) |> List.first() |> Map.get(:value) |> List.first()

      rss_description =
        body |> Quinn.find(:description) |> List.first() |> Map.get(:value) |> List.first()

      feed |> Map.put(:title, rss_title) |> Map.put(:description, rss_description)
    else
      atom_title = body |> Quinn.find(:title) |> List.first() |> Map.get(:value) |> List.first()

      atom_description =
        body |> Quinn.find(:subtitle) |> List.first(%{}) |> Map.get(:value, [""]) |> List.first()

      feed |> Map.put(:title, atom_title) |> Map.put(:description, atom_description)
    end
  end

  # Fetches feed items, updates the feed and search index
  def fetch_feed_items(%Feed{} = feed) do
    Logger.info("Fetch items for feed: #{feed.title}")

    data = Parser.parse_for_url(feed.url)

    item_tags =
      data |> Map.get(:items) |> Enum.reduce([], fn item, acc -> acc ++ Map.get(item, :tags) end)

    feed_tags = data |> Map.get(:tags)

    all_parsed_tags_flat =
      (item_tags ++ feed_tags)
      |> Enum.uniq()

    # Start transaction
    Repo.transaction(fn ->
      # Store every found tag in the database.
      # In case the tag already exists, don't do anything to it
      create_tags_from_list(all_parsed_tags_flat)

      # Fetch tags from db as the 'insert_all' on_conflict: :nothing, does not return the list of entries
      tags_from_db = Repo.all(from t in Tag, where: t.title in ^all_parsed_tags_flat)

      # Make sure 'tags' are loaded for feed
      feed = Repo.one(from(f in Feed, where: f.id == ^feed.id, preload: [:tags]))

      updated_tags_for_feed =
        tags_from_db
        |> Enum.filter(fn t -> Enum.member?(feed_tags, t.title) end)
        |> Enum.concat(feed.tags)

      feed
      |> Feed.changeset(Map.from_struct(feed))
      |> Ecto.Changeset.put_assoc(:tags, updated_tags_for_feed)
      |> Repo.update()

      item_changesets =
        data
        |> Map.get(:items)
        |> Enum.map(fn item ->
          item_tags = item |> Map.get(:tags)

          Item.changeset(%Item{}, %{
            published_at: Map.get(item, :published_at),
            guid: Map.get(item, :guid),
            title: Map.get(item, :title),
            link: Map.get(item, :link),
            description: Map.get(item, :description),
            content: Map.get(item, :content)
          })
          |> Ecto.Changeset.put_change(:feed_id, feed.id)
          |> Ecto.Changeset.put_assoc(
            :tags,
            tags_from_db |> Enum.filter(fn t -> Enum.member?(item_tags, t.title) end)
          )
        end)

      # Filter out any existing items we have
      existing_ids =
        item_changesets
        |> Enum.map(fn item -> Ecto.Changeset.get_field(item, :guid) end)
        |> (fn item_ids ->
              Repo.all(
                from item in Item, where: item.guid in ^item_ids, select: %{guid: item.guid}
              )
            end).()
        |> Enum.map(fn entry -> entry.guid end)

      new_items =
        item_changesets
        |> Enum.filter(fn item -> Ecto.Changeset.get_field(item, :guid) not in existing_ids end)

      new_item_guids = new_items |> Enum.map(fn item -> Ecto.Changeset.get_field(item, :guid) end)

      res =
        new_items
        |> Enum.with_index()
        |> Enum.reduce(
          Ecto.Multi.new(),
          fn {changeset, idx}, multi ->
            Ecto.Multi.insert(multi, Integer.to_string(idx), changeset)
          end
        )
        |> Repo.transaction()

      # Add search index
      Item
      |> where([item], item.guid in ^new_item_guids)
      |> Repo.all()
      |> recalculate_search_index_for_items()

      res
    end)
  end

  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  def mark_item_as_read(%Item{:is_read => true} = item), do: {:ok, item}

  def mark_item_as_read(%Item{} = item) do
    update_item(item, %{is_read: true})
  end

  def mark_item_as_favoured(%Item{} = item) do
    # TODO: system tags should be more robust
    favourite_tag = Repo.one(from t in Tag, where: t.title == "Favourite")
    tags = item |> Map.get(:tags)

    item
    |> Item.changeset(%{})
    |> Ecto.Changeset.put_assoc(:tags, [favourite_tag | tags])
    |> Repo.update()
  end

  def mark_item_as_non_favoured(%Item{} = item) do
    favourite_tag = Repo.one(from t in Tag, where: t.title == "Favourite")
    tags = item |> Map.get(:tags) |> Enum.filter(fn t -> t.id != favourite_tag.id end)

    item
    |> Item.changeset(%{})
    |> Ecto.Changeset.put_assoc(:tags, tags, [%{}])
    |> Repo.update()
  end

  def get_feed_items_unread_count!(feed) do
    [count] =
      Repo.all(from i in Item, where: [feed_id: ^feed.id, is_read: false], select: count(i.id))

    count
  end

  # In case empty list, do nothing
  def recalculate_search_index_for_items([]), do: :ok

  def recalculate_search_index_for_items(items = [_ | _]) do
    ids = items |> Enum.map(fn i -> i.id end)
    sql = "
    WITH cte AS (
        SELECT 
            items.id,
            (
                to_tsvector(coalesce(items.title, '')) || 
                to_tsvector(coalesce(items.description, '')) ||
                to_tsvector(coalesce(items.content, ''))
            ) AS document
        FROM items
        WHERE items.id IN (#{1..length(ids) |> Enum.map(fn i -> '$#{i}' end) |> Enum.join(",")}) -- List the IDs you want to update
    )
    UPDATE items
    SET _search_tsv = cte.document
    FROM cte
    WHERE items.id = cte.id;
      "
    {:ok, _} = Repo.query(sql, ids)
    :ok
  end

  def fetch_feed_items_for_all_feeds() do
    query = from(feed in Feed)
    max_rows = 10

    # Repo.stream has to be called inside transaction
    Repo.transaction(
      fn ->
        query
        |> Repo.stream([{:max_rows, max_rows}])
        |> Stream.chunk_every(max_rows)
        |> Enum.each(fn batch ->
          batch
          |> Enum.map(fn feed ->
            try do
              fetch_feed_items(feed)
            rescue
              _ ->
                IO.warn("Failed to fetch feed for #{feed.title}")
            end
          end)
        end)
      end,
      # 10 minute
      timeout: 1000 * 60 * 10
    )
  end
end
