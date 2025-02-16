defmodule Up.Engine.Prod do
  @moduledoc false
  @behaviour Up.Engine

  alias Up.Services.BFL

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

  # Updated output handler to support maps with a "sample" key.
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
end
