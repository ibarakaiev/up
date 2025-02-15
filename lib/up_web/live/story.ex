defmodule UpWeb.Live.Products.Dynamic.Story do
  @moduledoc false
  use UpWeb, :live_view

  alias Up.Products.Dynamic.Story
  alias Up.Services.S3
  alias Up.Engine

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-screen-sm">
      <h1 class="text-3xl font-bold">Generate a story</h1>
      <p class="mt-6">
        Welcome to story {@story.hash}.
      </p>
      <p class="mt-6">
        Description one: {@story.person_one_description}.
      </p>
      <p class="mt-6">
        Description one: {@story.person_two_description}.
      </p>
    </div>
    """
  end

  @impl true
  def mount(%{"hash" => hash} = _params, _session, socket) do
    story = Story.get_by_hash!(hash)
    {:ok, assign(socket, story: story)}
  end
end
