defmodule NewsbloatWeb.SidebarMenuComponent do
  use NewsbloatWeb, :live_component

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  def update(assings, socket) do
    {:ok,
     socket
     |> merge_parent_assigns(assings)
     |> assign(:current_feed, Map.get(assings, :current_feed, %Feed{}))
     |> assign(:feeds, list_feeds())}
  end

  defp merge_parent_assigns(socket, assigns) do
    merged_socket =
      Enum.reduce(assigns, socket, fn {key, val}, updated_socket ->
        updated_socket |> assign(key, val)
      end)

    merged_socket
  end

  defp list_feeds do
    page = RSS.list_feeds()

    page
    |> Enum.map(fn feed ->
      %{
        :feed => feed,
        # TODO: probably should fetch unread count with the same query, not like this
        :unread_count => RSS.get_feed_items_unread_count!(feed)
      }
    end)
  end

  # TODO: this component should be at root level with connected socket (without needing to do full re-render on page changes)
  def render(assigns) do
    # IO.inspect ["assigns", assigns]
    get_feed_title = fn feed, unread_count ->
      if unread_count != 0 do
        feed.title <> " (" <> to_string(unread_count) <> ")"
      else
        feed.title
      end
    end

    get_ui_theme_link = fn ui_theme ->
      if ui_theme == "dark" do
        "?ui_theme=light"
      else
        "?ui_theme=dark"
      end
    end

    ~L"""
    <section x-data="{ isOpen: false }" x-bind:class="isOpen ? 'bg-background w-64 shadow-lg h-screen overflow-y-auto' : 'bg-transparent w-0'" class="fixed top-0 p-4 z-10">
    <button class="bg-background group" @click="isOpen = ! isOpen">
      <%= icon_tag(@socket, "menu", class: "w-4 h-4 transform transition-transform group-hover:rotate-90") %>
    </button>
      <div x-show="isOpen">
        <h3>Feeds</h3>

        <ul class="mb-4">
          <%= for %{ :feed => feed, :unread_count => unread_count } <- @feeds do %>
            <li>
            <%= live_redirect get_feed_title.(feed, unread_count), to: Routes.feed_show_path(@socket, :show, feed), class: if @current_feed.id == feed.id, do: "link p-2 w-full truncate active", else: "link p-2 truncate w-full" %>
            </li>
          <% end %>
        </ul>
        <ul class="mb-4">
          <li>
            <%= live_patch "New Feed", to: Routes.feed_index_path(@socket, :new), class: "link p-2" %>
          </li>
        </ul>
        <ul class="mb-4">
          <li>
              <a href="/" class="link p-2">
                Home
              </a>
          </li>
          <li class="ml-auto mr-0">
          <li>
            <%= link_with_html to: Routes.search_index_path(@socket, :index), class: "link p-2" do
              {_, svg } = icon_tag(@socket, "search", class: "w-4 h-4 inline-block mr-2")
              Enum.join([svg, "Search"], " ")
            end %>
          </li>
          </li>
        </ul>
        <ul>
          <li>
          <%= link_with_html to: Routes.path(@socket, get_ui_theme_link.(@ui_theme)), class: "link p-2" do
            {_, svg } = icon_tag(@socket, "light-bulb", class: "w-4 h-4 inline-block mr-2")
            Enum.join([svg, "Apperance: ", String.capitalize(@ui_theme)], " ")
          end %>
          </li>
        </ul>
      </div>
    </section>
    """
  end
end
