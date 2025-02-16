defmodule Up.Products.Dynamic.Story.Workers.TransitionToFramesGenerated do
  @moduledoc false
  use Oban.Worker,
    queue: :default,
    max_attempts: 4,
    unique: [states: [:executing, :scheduled, :retryable]]

  alias Up.Products.Dynamic.Story

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(90)

  @impl Oban.Worker
  def perform(%{args: %{"hash" => story_hash} = _args}) do
    story = Story.get_by_hash!(story_hash)

    if length(story.frames) == Story.total_prompts() do
      Story.mark_as_frames_generated(story)
    else
      {:snooze, 3}
    end
  end
end
