defmodule Up.Products.Dynamic.Story.Actions.GenerateFrames do
  @moduledoc false
  use Ash.Resource.ManualUpdate

  alias Up.Products.Dynamic.Story.Workers
  alias Up.Products.Dynamic.Story

  @impl true
  def update(changeset, _opts, _context) do
    story = changeset.data

    for {prompt, frame_number} <- Enum.with_index(Story.prompts(), 1) do
      %{"hash" => story.hash, "prompt" => prompt, "frame_number" => frame_number}
      |> Workers.GenerateFrame.new()
      |> Oban.insert!()
    end

    %{"hash" => story.hash}
    |> Workers.TransitionToFramesGenerated.new()
    |> Oban.insert!()

    {:ok, story}
  end
end
