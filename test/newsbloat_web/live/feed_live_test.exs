defmodule NewsbloatWeb.FeedLiveTest do
  use NewsbloatWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Newsbloat.RSS

  @create_attrs %{description: "some description", url: "some url", title: "some title"}
  @update_attrs %{description: "some updated description", url: "some updated url", title: "some updated title"}
  @invalid_attrs %{description: nil, url: nil, title: nil}

  defp fixture(:feed) do
    {:ok, feed} = RSS.create_feed(@create_attrs)
    feed
  end

  defp create_feed(_) do
    feed = fixture(:feed)
    %{feed: feed}
  end

  describe "Index" do
    setup [:create_feed]

    test "lists all feeds", %{conn: conn, feed: feed} do
      {:ok, _index_live, html} = live(conn, Routes.feed_index_path(conn, :index))

      assert html =~ "Listing Feeds"
      assert html =~ feed.description
    end

    test "saves new feed", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.feed_index_path(conn, :index))

      assert index_live |> element("a", "New Feed") |> render_click() =~
               "New Feed"

      assert_patch(index_live, Routes.feed_index_path(conn, :new))

      assert index_live
             |> form("#feed-form", feed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#feed-form", feed: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.feed_index_path(conn, :index))

      assert html =~ "Feed created successfully"
      assert html =~ "some description"
    end

    test "updates feed in listing", %{conn: conn, feed: feed} do
      {:ok, index_live, _html} = live(conn, Routes.feed_index_path(conn, :index))

      assert index_live |> element("#feed-#{feed.id} a", "Edit") |> render_click() =~
               "Edit Feed"

      assert_patch(index_live, Routes.feed_index_path(conn, :edit, feed))

      assert index_live
             |> form("#feed-form", feed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#feed-form", feed: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.feed_index_path(conn, :index))

      assert html =~ "Feed updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes feed in listing", %{conn: conn, feed: feed} do
      {:ok, index_live, _html} = live(conn, Routes.feed_index_path(conn, :index))

      assert index_live |> element("#feed-#{feed.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#feed-#{feed.id}")
    end
  end

  describe "Show" do
    setup [:create_feed]

    test "displays feed", %{conn: conn, feed: feed} do
      {:ok, _show_live, html} = live(conn, Routes.feed_show_path(conn, :show, feed))

      assert html =~ "Show Feed"
      assert html =~ feed.description
    end

    test "updates feed within modal", %{conn: conn, feed: feed} do
      {:ok, show_live, _html} = live(conn, Routes.feed_show_path(conn, :show, feed))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Feed"

      assert_patch(show_live, Routes.feed_show_path(conn, :edit, feed))

      assert show_live
             |> form("#feed-form", feed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#feed-form", feed: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.feed_show_path(conn, :show, feed))

      assert html =~ "Feed updated successfully"
      assert html =~ "some updated description"
    end
  end
end
