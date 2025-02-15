defmodule Imaginara.Products.Dynamic.Book.Actions.AddStorylineQuestion do
  @moduledoc false
  use Ash.Resource.ManualUpdate

  alias Imaginara.Products.Dynamic.Book

  @impl true
  def update(changeset, _opts, _context) do
    story = changeset.data

    for {prompt, frame_number} <- Enum.with_index(prompts(), 1) do
      %{"hash" => story.hash, "prompt" => prompt, "frame_number" => frame_number}
      |> Workers.GenerateFrame.new()
      |> Oban.insert!()
    end

    %{"hash" => story.hash}
    |> Workers.TransitionToFramesGenerated.new()
    |> Oban.insert!()

    {:ok, story}
  end

  def prompts do
  end
end
