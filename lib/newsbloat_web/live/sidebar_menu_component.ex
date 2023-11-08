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
    get_ui_theme_link = fn ui_theme ->
      if ui_theme == "dark" do
        "?ui_theme=light"
      else
        "?ui_theme=dark"
      end
    end

    ~L"""
    <!-- MOBILE MENU -->
    <section
      x-data="{ isOpen: false }"
      x-bind:class="isOpen ? 'bg-background shadow-lg w-screen h-screen overflow-y-auto pb-16' : 'bg-transparent w-0'"
      class="fixed lg:hidden top-0 p-4 z-10"
      @click.outside="isOpen = false"
    >
    <button class="fixed bottom-0 right-0 m-4 lg:m-0 bg-background group z-10" @click="isOpen = ! isOpen">
      <%= icon_tag(@socket, "menu", class: "w-4 h-4 transform transition-transform group-hover:rotate-90") %>
    </button>
      <div x-show="isOpen">
        <h3>
          <%= link NewsbloatWeb.Gettext.ngettext("Feed", "Feeds", 2), to: Routes.feed_index_path(@socket, :index) %>
        </h3>

        <%= live_component NewsbloatWeb.FeedListComponent, current_feed: @current_feed %>
        <ul class="mb-4">
          <li>
            <%= live_patch NewsbloatWeb.Gettext.gettext("New Feed"), to: Routes.feed_index_path(@socket, :new), class: "link p-2" %>
          </li>
        </ul>
        <ul class="mb-4">
          <li class="ml-auto mr-0">
          <li>
            <%= link_with_html to: Routes.search_index_path(@socket, :index), class: "link p-2" do
              {_, svg } = icon_tag(@socket, "search", class: "w-4 h-4 inline-block mr-2")
              Enum.join([svg, NewsbloatWeb.Gettext.gettext("Search")], " ")
            end %>
          </li>
          </li>
        </ul>
        <ul>
          <li>
          <%= link_with_html to: Routes.path(@socket, get_ui_theme_link.(@ui_theme)), class: "link p-2" do
            {_, svg } = icon_tag(@socket, "light-bulb", class: "w-4 h-4 inline-block mr-2")
            Enum.join([svg, NewsbloatWeb.Gettext.gettext("Apperance")<>": ", String.capitalize(@ui_theme)], " ")
          end %>
          </li>
        </ul>
        <%= live_component NewsbloatWeb.Components.LangSelectorComponent %>
      </div>
    </section>
    <!-- END MOBILE MENU -->

    <!-- DESKTOP MENU -->
    <section
      x-data="{ isOpen: true }"
      x-bind:class="isOpen ? 'bg-background shadow-lg w-64 h-screen z-1 overflow-y-auto pb-16' : 'bg-transparent w-0'"
      class="fixed hidden lg:block top-0 p-4"
    >
    <button class="fixed lg:relative bottom-0 right-0 m-4 m-0 bg-background group z-10" @click="isOpen = ! isOpen">
      <%= icon_tag(@socket, "menu", class: "w-4 h-4 transform transition-transform group-hover:rotate-90") %>
    </button>
      <div x-show="isOpen">
        <h3>
          <%= link NewsbloatWeb.Gettext.ngettext("Feed", "Feeds", 2), to: Routes.feed_index_path(@socket, :index) %>
        </h3>

        
        <%= live_component NewsbloatWeb.FeedListComponent, current_feed: @current_feed %>
        <ul class="mb-4">
          <li>
            <%= live_patch NewsbloatWeb.Gettext.gettext("New Feed"), to: Routes.feed_index_path(@socket, :new), class: "link p-2" %>
          </li>
        </ul>
        <ul class="mb-4">
          <li class="ml-auto mr-0">
          <li>
            <%= link_with_html to: Routes.search_index_path(@socket, :index), class: "link p-2" do
              {_, svg } = icon_tag(@socket, "search", class: "w-4 h-4 inline-block mr-2")
              Enum.join([svg, NewsbloatWeb.Gettext.gettext("Search")], " ")
            end %>
          </li>
          </li>
        </ul>
        <ul>
          <li>
          <%= link_with_html to: Routes.path(@socket, get_ui_theme_link.(@ui_theme)), class: "link p-2" do
            {_, svg } = icon_tag(@socket, "light-bulb", class: "w-4 h-4 inline-block mr-2")
            Enum.join([svg, NewsbloatWeb.Gettext.gettext("Apperance")<>": ", String.capitalize(@ui_theme)], " ")
          end %>
          </li>
        </ul>
        <%= live_component NewsbloatWeb.Components.LangSelectorComponent %>
      </div>
    </section>

    <!-- END DESKTOP MENU -->

    """
  end
end
