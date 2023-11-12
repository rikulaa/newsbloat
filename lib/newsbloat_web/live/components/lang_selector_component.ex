defmodule NewsbloatWeb.Components.LangSelectorComponent do
  use NewsbloatWeb, :live_component

  # TODO: this component should be at root level with connected socket (without needing to do full re-render on page changes)
  def render(assigns) do
    ~L"""
    <div x-data="{ isLangSelectorOpen: false }" class="mb-4">
      <button class="plain p-2" @click="isLangSelectorOpen = !isLangSelectorOpen">
      <div class="mr-2 inline-block">
        <span class="inline-block transform transition" x-bind:class="isLangSelectorOpen ? 'rotate-180' : ''">
        <%= icon_tag(@socket, "angle-down", class: "w-4 h-4 inline-block") %>
        </span>
      </div>
        <span class="inline-block">
          <%= NewsbloatWeb.Gettext.gettext("Language") %>
        </span>
      </button>
      <ul class="p-2 pt-0" x-show="isLangSelectorOpen">
        <%= for lang <- NewsbloatWeb.Gettext.list_known_locales() do %>
          <li class="flex">
            <span class="invisible inline-block w-8"></span>
            <%= link lang, to: Routes.feed_index_path(@socket, :index, _lang: lang), class: "link w-8 py-1" %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
