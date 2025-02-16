defmodule UpWeb.Live.Products.Dynamic.Story.Slideshow do
  use UpWeb, :live_view

  alias Up.Products.Dynamic.Story

  @slide_interval 8_000

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-screen-lg mx-auto">
      <div class="rounded-xl overflow-hidden" id="slideshow-container" phx-hook="PlaySong">
        <img
          src={@current_frame.image_url}
          phx-hook="FadeInOut"
          class="max-h-full"
          id={@current_frame.id}
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"hash" => hash} = _params, _session, socket) do
    story = Story.get_by_hash!(hash)
    # Ensure frames are ordered by frame_number
    frames = Enum.sort_by(story.frames, & &1.frame_number)
    # Get the first frame (or a placeholder if there are no frames)
    first_frame = List.first(frames) || %{frame_number: 1, image_url: nil}

    if connected?(socket) do
      Process.send_after(self(), :next_frame, @slide_interval)
    end

    {:ok,
     assign(socket,
       story: story,
       frames: frames,
       frame_index: 0,
       current_frame: first_frame
     )}
  end

  @impl true
  def handle_info(:next_frame, socket) do
    frames = socket.assigns.frames
    total_frames = length(frames)

    # Compute the next frame index; loop back to 0 when at the end.
    next_index = rem(socket.assigns.frame_index + 1, total_frames)
    next_frame = Enum.at(frames, next_index)

    if connected?(socket) do
      Process.send_after(self(), :next_frame, @slide_interval)
    end

    {:noreply, assign(socket, frame_index: next_index, current_frame: next_frame)}
  end
end
