defmodule Up.Engine.Prod do
  @moduledoc false
  @behaviour Up.Engine

  alias Up.Services.BFL
  alias Up.Services.Runway

  require Logger

  @impl true
  def generate_text(prompt_schema, params, opts \\ []) do
    Logger.debug([step: prompt_schema] ++ params)

    Instructor.chat_completion(
      messages: prompt_schema.prompt(params),
      model: Keyword.get(opts, :model, "gpt-4o"),
      response_model: prompt_schema,
      max_retries: Keyword.get(opts, :max_retries, 3)
    )
  end

  @impl true
  def generate_image(prompt, opts \\ []) when is_binary(prompt) do
    Logger.debug(prompt: prompt)

    case BFL.predict(prompt, opts) do
      {:ok, output} -> handle_output(output)
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  @doc """
  Generates a video by accepting two arguments: `prompt_image` and `prompt_text`.

  ## Parameters

    - `prompt_image`: a binary containing the URL or data URI for the first frame.
    - `prompt_text`: a binary describing what should appear in the video.
    - `opts`: an optional keyword list for additional settings like `"duration"`, `"seed"`, etc.

  The defaults are:
    - `"model"`: `"gen3a_turbo"`
    - `"duration"`: `10`
    - `"watermark"`: `false`
  """
  def generate_video(prompt_image, prompt_text, opts \\ [])
      when is_binary(prompt_image) and is_binary(prompt_text) do
    Logger.debug(prompt_image: prompt_image, prompt_text: prompt_text)

    defaults = %{
      "model" => "gen3a_turbo",
      "duration" => 10,
      "watermark" => false
    }

    payload =
      defaults
      |> Map.merge(%{
        "promptImage" => prompt_image,
        "promptText" => prompt_text
      })
      |> Map.merge(Enum.into(opts, %{}))

    case Runway.generate_video(payload) do
      {:ok, output} -> handle_video_output(output)
      {:error, error} -> {:error, error}
    end
  end

  # Handles image outputs.
  defp handle_output(%{"sample" => url}) when is_binary(url) do
    {:ok, url}
  end

  defp handle_output([url | _]) when is_binary(url) do
    {:ok, url}
  end

  defp handle_output(url) when is_binary(url) do
    if String.starts_with?(url, "https://") do
      {:ok, url}
    else
      {:error, "Unexpected output format: #{inspect(url)}"}
    end
  end

  defp handle_output(other) do
    {:error, "Unexpected output format: #{inspect(other)}"}
  end

  # Handles video outputs.
  defp handle_video_output(output) when is_binary(output) do
    {:ok, output}
  end

  defp handle_video_output(other) do
    {:error, "Unexpected video output format: #{inspect(other)}"}
  end
end
