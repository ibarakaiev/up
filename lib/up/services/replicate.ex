defmodule Up.Services.Replicate do
  @moduledoc false

  def predict!(model_name, input) do
    case predict(model_name, input) do
      {:ok, output} -> output
      {:error, reason} -> raise "Replicate API request failed: #{inspect(reason)}"
    end
  end

  def predict(model_name, input) do
    case Req.post(base_req(),
           url: "https://api.replicate.com/v1/models/#{model_name}/predictions",
           body: Jason.encode!(%{input: input}),
           receive_timeout: 120_000
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status >= 200 and status < 300 ->
        handle_prediction_status(body)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_prediction(prediction_id) do
    case Req.get(base_req(),
           url: "https://api.replicate.com/v1/predictions/#{prediction_id}"
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status >= 200 and status < 300 ->
        handle_prediction_status(body)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_prediction_status(%{"status" => "succeeded", "output" => output}) do
    {:ok, output}
  end

  defp handle_prediction_status(%{"status" => "failed", "error" => error}) do
    if String.contains?(error, "NSFW") do
      {:error, :nsfw}
    else
      {:error, error}
    end
  end

  defp handle_prediction_status(%{"status" => status, "id" => prediction_id})
       when status == "starting" or status == "processing" do
    poll_prediction(prediction_id, 5)
  end

  defp handle_prediction_status(response) do
    {:error, "Unexpected response: #{inspect(response)}"}
  end

  defp poll_prediction(prediction_id, interval_seconds) do
    :timer.sleep(interval_seconds * 1_000)

    case get_prediction(prediction_id) do
      {:ok, output} -> {:ok, output}
      {:error, reason} -> {:error, reason}
    end
  end

  defp base_req do
    Req.new(
      headers: [
        {"Authorization", "Bearer " <> System.get_env("REPLICATE_API_TOKEN")},
        {"Content-Type", "application/json"},
        {"Prefer", "wait=60"}
      ],
      receive_timeout: 120_000
    )
  end
end
