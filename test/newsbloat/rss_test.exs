defmodule Newsbloat.RSSTest do
  use Newsbloat.DataCase

  alias Newsbloat.RSS

  describe "feeds" do
    alias Newsbloat.RSS.Feed

    @valid_attrs %{description: "some description", url: "some url", title: "some title"}
    @update_attrs %{description: "some updated description", url: "some updated url", title: "some updated title"}
    @invalid_attrs %{description: nil, url: nil, title: nil}

    def feed_fixture(attrs \\ %{}) do
      {:ok, feed} =
        attrs
        |> Enum.into(@valid_attrs)
        |> RSS.create_feed()

      feed
    end

    test "list_feeds/0 returns all feeds" do
      feed = feed_fixture()
      assert RSS.list_feeds() == [feed]
    end

    test "get_feed!/1 returns the feed with given id" do
      feed = feed_fixture()
      assert RSS.get_feed!(feed.id) == feed
    end

    test "create_feed/1 with valid data creates a feed" do
      assert {:ok, %Feed{} = feed} = RSS.create_feed(@valid_attrs)
      assert feed.description == "some description"
      assert feed.url == "some url"
      assert feed.title == "some title"
    end

    test "create_feed/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = RSS.create_feed(@invalid_attrs)
    end

    test "update_feed/2 with valid data updates the feed" do
      feed = feed_fixture()
      assert {:ok, %Feed{} = feed} = RSS.update_feed(feed, @update_attrs)
      assert feed.description == "some updated description"
      assert feed.url == "some updated url"
      assert feed.title == "some updated title"
    end

    test "update_feed/2 with invalid data returns error changeset" do
      feed = feed_fixture()
      assert {:error, %Ecto.Changeset{}} = RSS.update_feed(feed, @invalid_attrs)
      assert feed == RSS.get_feed!(feed.id)
    end

    test "delete_feed/1 deletes the feed" do
      feed = feed_fixture()
      assert {:ok, %Feed{}} = RSS.delete_feed(feed)
      assert_raise Ecto.NoResultsError, fn -> RSS.get_feed!(feed.id) end
    end

    test "change_feed/1 returns a feed changeset" do
      feed = feed_fixture()
      assert %Ecto.Changeset{} = RSS.change_feed(feed)
    end
  end
end
