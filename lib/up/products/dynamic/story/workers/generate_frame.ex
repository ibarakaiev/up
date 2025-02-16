defmodule Up.Products.Dynamic.Story.Workers.GenerateFrame do
  @moduledoc false
  use Oban.Worker,
    queue: :default,
    max_attempts: 4,
    unique: [states: [:executing, :scheduled, :retryable]]

  alias Up.Products.Dynamic.Story
  alias Up.Products.Dynamic.Story.Frame
  alias Up.Engine
  alias Up.Services.S3

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

    # TOK is used to trigger the fine-tuned model
    {:ok, image_url} = Engine.generate_image("#{prompt} TOK")

    uploaded_url =
      S3.upload_from_url!(
        "stories/#{story.hash}/frame_#{frame_number}.webp",
        image_url
      )

    Frame.create(%{frame_number: frame_number, image_url: uploaded_url, story_id: story.id})
  end
end
