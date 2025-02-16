defmodule Up.Engine.Prod do
  @moduledoc false
  @behaviour Up.Engine

  # alias Up.Services.Replicate

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
  def generate_image(prompt, opts \\ []) do
    :ok
    # Logger.debug(prompt: prompt)
    #
    # input = %{
    #   "cfg" => Keyword.get(opts, :cfg, 4.5),
    #   "prompt" => prompt,
    #   "steps" => Keyword.get(opts, :steps, 40),
    #   "width" => Keyword.get(opts, :width, 1440),
    #   "height" => Keyword.get(opts, :height, 1440)
    # }
    #
    # case Replicate.predict(
    #        Keyword.get(opts, :model, "black-forest-labs/flux-1.1-pro-ultra"),
    #        input
    #      ) do
    #   {:ok, output} -> handle_output(output)
    #   {:error, error} -> {:error, error}
    # end
  end

  # defp handle_output(output) do
  #   case output do
  #     ["data:image" <> _ | _] ->
  #       raise "Base64 image responses are not supported"
  #
  #     [url | _] ->
  #       {:ok, url}
  #
  #     "https://" <> _rest = url ->
  #       {:ok, url}
  #
  #     other ->
  #       {:error, "Unexpected output format: #{inspect(other)}"}
  #   end
  # end
end
