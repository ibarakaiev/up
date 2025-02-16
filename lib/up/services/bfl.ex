defmodule Up.Services.BFL do
  @moduledoc """
  Provides a simple interface to run BFL inferences.

  ## Usage

      # Run an inference job using the default model and finetune_id:
      {:ok, output} =
        Up.Services.BFL.predict("image of a TOK")

      # Run an inference job with a custom model and finetune_id:
      {:ok, output} =
        Up.Services.BFL.predict("image of a TOK",
          model_name: "custom-model-name",
          finetune_id: "your_finetune_id"
        )

      # Or raise on error:
      output =
        Up.Services.BFL.predict!("image of a TOK", finetune_id: "your_finetune_id")
  """

  @bfl_base_url "https://api.us1.bfl.ai/v1"
  @default_model "flux-pro-1.1-ultra-finetuned"
  @default_finetune_id "b932a4da-edca-473b-89af-4d9ce558fc38"

  @doc """
  Runs a BFL inference and returns `{:ok, output}` or `{:error, reason}`.

  ## Parameters

    - prompt: A string prompt to pass to the inference engine.
    - opts: An optional keyword list. Supported keys:
      - `:model_name` - The model endpoint (defaults to `"flux-pro-1.1-ultra-finetuned"`).
      - `:finetune_id` - The finetune ID (defaults to `"6eab22d1-a868-4827-bf4f-72fb8b96f78f"`).
  """
  def predict(prompt, opts \\ []) when is_binary(prompt) do
    model_name = Keyword.get(opts, :model_name, @default_model)
    finetune_id = Keyword.get(opts, :finetune_id, @default_finetune_id)

    payload = %{
      "finetune_strength" => 1.2,
      "prompt" => prompt,
      "finetune_id" => finetune_id
    }

    url = "#{@bfl_base_url}/#{model_name}"

    case Req.post(
           base_req(),
           url: url,
           body: Jason.encode!(payload),
           receive_timeout: 120_000
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        handle_inference_status(body)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Similar to `predict/2` but raises an exception on error.
  """
  def predict!(prompt, opts \\ []) when is_binary(prompt) do
    case predict(prompt, opts) do
      {:ok, output} ->
        output

      {:error, reason} ->
        raise "BFL API request failed: #{inspect(reason)}"
    end
  end

  @doc """
  Polls the BFL API for the result of an inference job given its ID.
  """
  def get_inference(inference_id) do
    case Req.get(
           base_req(),
           url: "#{@bfl_base_url}/get_result",
           params: %{"id" => inference_id}
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        handle_inference_status(body)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private Functions

  # When the job is ready, return the result.
  defp handle_inference_status(%{"status" => "Ready", "result" => output}) do
    {:ok, output}
  end

  # When the job is still processing, poll for the result.
  defp handle_inference_status(%{"status" => status, "id" => inference_id})
       when status in ["Pending", "Processing"] do
    poll_inference(inference_id, 5)
  end

  # When the response contains an id and polling_url without a status,
  # assume it needs to be polled.
  defp handle_inference_status(%{"id" => inference_id, "polling_url" => _url}) do
    poll_inference(inference_id, 5)
  end

  # When the job failed, return the error.
  defp handle_inference_status(%{"status" => "Failed", "error" => error}) do
    {:error, error}
  end

  # Fallback for unexpected responses.
  defp handle_inference_status(response) do
    {:error, "Unexpected response: #{inspect(response)}"}
  end

  # Polls for the inference result after a given delay (in seconds)
  defp poll_inference(inference_id, interval_seconds) do
    :timer.sleep(interval_seconds * 1_000)
    get_inference(inference_id)
  end

  defp base_req do
    Req.new(
      headers: [
        {"X-Key", System.get_env("BFL_API_KEY")},
        {"Content-Type", "application/json"}
      ],
      receive_timeout: 120_000
    )
  end
end
