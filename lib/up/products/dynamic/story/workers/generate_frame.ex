defmodule Up.Products.Dynamic.Story.Workers.GenerateFrame do
  @moduledoc false
  use Oban.Worker,
    queue: :default,
    max_attempts: 4,
    unique: [states: [:executing, :scheduled, :retryable]]

  alias Up.Products.Dynamic.Story
  alias Up.Products.Dynamic.Story.Frame
  alias Up.Engine

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(90)

  @impl Oban.Worker
  def perform(%{
        args: %{"hash" => story_hash, "prompt" => prompt, "frame_number" => frame_number} = _args
      }) do
    story = Story.get_by_hash!(story_hash)

    {:ok, prompt} =
      case Engine.generate_text(Story.PromptSchemas.HydratePrompt, %{story: story, prompt: prompt}) do
        {:ok, %{prompt: prompt}} ->
          {:ok, prompt}
      end

    {:ok, image_url} = Engine.generate_image(prompt)

    Frame.create(%{frame_number: frame_number, image_url: image_url, story_id: story.id})
  end
end
