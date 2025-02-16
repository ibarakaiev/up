defmodule UpWeb.Live.Products.Dynamic.Story do
  @moduledoc false
  use UpWeb, :live_view

  alias Up.Products.Dynamic.Story
  alias UpWeb.Endpoint

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-screen-lg">
      <div class="mx-auto max-w-screen-sm">
        <h1 class="text-3xl font-bold">Your story</h1>
        <p
          :if={@story.state == :initialized}
          class="italic mt-6"
          id="story-is-being-generated"
          phx-hook="LoadingEllipsis"
        >
          The illustrations for your story are being generated
        </p>
        <p :if={@story.state == :frames_generated} class="italic mt-6">Your story is now ready.</p>
      </div>

      <div class="grid grid-cols-3 mt-16 gap-x-6 gap-y-4">
        <div
          :for={frame <- populate_missing_frames(@story.frames, Story.total_prompts())}
          class="rounded-lg overflow-hidden"
        >
          <div
            :if={is_nil(frame.image_url)}
            class="bg-zinc-200 inset flex justify-center items-center text-zinc-800 h-48 shadow-inner"
          >
            <p id={"frame-#{frame.frame_number}"} phx-hook="LoadingEllipsis" class="w-12">
              {frame.frame_number}
            </p>
          </div>
          <img :if={not is_nil(frame.image_url)} src={frame.image_url} class="h-48" />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"hash" => hash} = _params, _session, socket) do
    story = Story.get_by_hash!(hash)

    Endpoint.subscribe("story:updated:#{story.id}")

    {:ok, assign(socket, story: story)}
  end

  @impl true
  def handle_info(%{topic: "story:updated:" <> story_id} = _message, socket) do
    story = Story.get_by_id!(story_id)

    {:noreply, assign(socket, story: story)}
  end

  def populate_missing_frames(frames, total_frames) do
    # Create a map for quick lookup by frame_number
    frames_map = Map.new(frames, fn frame -> {frame.frame_number, frame} end)

    # Build a list from 1 to total_frames, getting each frame if it exists,
    # or defaulting to a map with a nil image_url.
    for frame_number <- 1..total_frames do
      Map.get(frames_map, frame_number, %{frame_number: frame_number, image_url: nil})
    end
  end
end
