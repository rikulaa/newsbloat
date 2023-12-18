defmodule Newsbloat.RSS.Parser do
  alias Quinn

  def parse_for_url(url) when is_binary(url) and byte_size(url) > 0 do
    url
    |> fetch_feed()
    |> parse()
  end

  defp fetch_feed(url) do
    HTTPoison.get(String.trim(url))
  end

  defp parse({:ok, %HTTPoison.Response{:status_code => 200} = response}) do
    body = response.body |> Quinn.parse()
    is_rss = body |> Quinn.find(:rss) |> length() > 0

    if is_rss do
      parse_rss(body)
    else
      parse_atom(body)
    end
  end

  # Parse rss feed
  def parse_rss([_ | _] = body) do
    title = body |> Quinn.find(:title) |> List.first() |> Map.get(:value) |> List.first()

    description =
      body |> Quinn.find(:description) |> List.first() |> Map.get(:value) |> List.first()

    feed_tags =
      body
      |> Quinn.find(:channel)
      |> List.first()
      |> (fn first -> if first != nil, do: first, else: %{} end).()
      |> Map.get(:value, [%{name: nil}])
      |> Enum.filter(fn x -> x.name == :category end)
      |> Enum.reduce([], fn cur, acc -> acc ++ cur.value end)
      |> sanitize_tag_list()

    items =
      body
      |> Quinn.find(:item)
      |> Enum.reverse()
      |> Enum.map(fn item ->
        %{value: value} = item

        link = get_value_from_map_list_by_key(value, :link)
        guid = generate_guid(get_value_from_map_list_by_key(value, :guid), link)

        content =
          get_value_from_map_list_by_key(value, :"content:encoded") ||
            get_value_from_map_list_by_key(value, :content)

        item_tags =
          item |> Quinn.find(:category) |> Enum.reduce([], fn cur, acc -> acc ++ cur.value end)

        %{
          :published_at => maybe_get_datetime(get_value_from_map_list_by_key(value, :pubDate)),
          :guid => guid,
          :title => get_value_from_map_list_by_key(value, :title),
          :link => link,
          :description => get_value_from_map_list_by_key(value, :description),
          :content => content,
          :tags => item_tags
        }
      end)

    response =
      %{}
      |> Map.put(:title, title)
      |> Map.put(:description, description)
      |> Map.put(:tags, feed_tags)
      |> Map.put(:items, items)

    response
  end

  # Parse atom feed
  def parse_atom([_ | _] = body) do
    title = body |> Quinn.find(:title) |> List.first() |> Map.get(:value) |> List.first()

    description =
      body |> Quinn.find(:subtitle) |> List.first(%{}) |> Map.get(:value, [""]) |> List.first()

    feed_tags =
      body
      |> Quinn.find(:feed)
      |> List.first()
      |> (fn first -> if first != nil, do: first, else: %{} end).()
      |> Map.get(:value, [%{name: nil}])
      |> Enum.filter(fn x -> x.name == :category end)
      |> Enum.reduce([], fn cur, acc -> acc ++ [cur.attr[:term]] end)
      |> sanitize_tag_list

    items =
      body
      |> Quinn.find(:entry)
      |> Enum.reverse()
      |> Enum.map(fn item ->
        %{value: value} = item

        # Generate guid from the id and link as feeds don't always have unique guids
        link = get_attr_value_from_map_list_by_key(value, :link, :href)
        guid = generate_guid(get_value_from_map_list_by_key(value, :id), link)

        content =
          get_value_from_map_list_by_key(value, :content) ||
            get_value_from_map_list_by_key(value, :summary)

        item_tags =
          item
          |> Quinn.find(:category)
          |> Enum.reduce([], fn cur, acc -> acc ++ [cur.attr[:term]] end)
          |> sanitize_tag_list()

        %{
          :published_at => maybe_get_datetime(get_value_from_map_list_by_key(value, :published)),
          :guid => guid,
          :title => get_value_from_map_list_by_key(value, :title),
          :link => link,
          :description => get_value_from_map_list_by_key(value, :summary),
          :content => content,
          :tags => item_tags
        }
      end)

    response =
      %{}
      |> Map.put(:title, title)
      |> Map.put(:description, description)
      |> Map.put(:tags, feed_tags)
      |> Map.put(:items, items)

    response
  end

  # Ugly utility functions below
  defp sanitize_tag_list(tag_list) do
    tag_list
    |> Stream.filter(fn tag -> tag != nil and tag != String.trim("") end)
    |> Stream.uniq()
    |> Enum.to_list()
  end

  defp get_value_from_map_list_by_key(map_list, key) do
    %{value: value} =
      map_list
      |> Enum.find(%{value: []}, fn i -> i.name === key end)

    value
    |> List.first()
  end

  defp get_attr_value_from_map_list_by_key(map_list, key, attr) do
    %{attr: attr_list} =
      map_list
      |> Enum.find(%{attr: []}, fn i -> i.name === key end)

    attr_list[attr]
  end

  defp maybe_get_datetime(timestamp) do
    case Timex.parse(timestamp, "{ISO:Extended}") do
      {:ok, parsed} -> parsed
      _ -> DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive()
    end
  end

  defp generate_guid(title, link) do
    to_string(title) <> ":" <> to_string(link)
  end
end
