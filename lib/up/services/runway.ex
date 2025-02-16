defmodule Up.Services.Runway do
  @moduledoc false

  @runway_version "2024-11-06"
  @base_url "https://api.dev.runwayml.com"

  @doc """
  Initiates a video generation task using the Runway API.

  The `input` parameter should be a map containing the required keys:
    - `"promptImage"` (string): a HTTPS URL or data URI for the initial image.
    - `"promptText"` (string): a description of what should appear in the video.

  Optional keys include:
    - `"model"` (defaults to `"gen3a_turbo"`)
    - `"seed"` (an integer between 0 and 4294967295)
    - `"watermark"` (boolean, defaults to false)
    - `"duration"` (integer in seconds, defaults to 10)
    - `"ratio"` (string: `"1280:768"` or `"768:1280"`)
  """
  def generate_video(input) when is_map(input) do
    case Req.post(base_req(),
           url: "#{@base_url}/v1/image_to_video",
           body: Jason.encode!(input)
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        case body do
          %{"id" => task_id} ->
            poll_task(task_id, 5)

          _ ->
            {:error, "Unexpected response format: #{inspect(body)}"}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieves the details of a previously submitted task.
  """
  def get_task(task_id) do
    case Req.get(base_req(),
           url: "#{@base_url}/v1/tasks/#{task_id}"
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Cancels (or deletes) a task.
  """
  def cancel_task(task_id) do
    case Req.delete(base_req(),
           url: "#{@base_url}/v1/tasks/#{task_id}"
         ) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Polls the task status every `interval_seconds` until a terminal state is reached.
  defp poll_task(task_id, interval_seconds) do
    :timer.sleep(interval_seconds * 1000)

    case get_task(task_id) do
      {:ok, %{"status" => status} = _body} when status in ["PENDING", "processing", "starting"] ->
        poll_task(task_id, interval_seconds)

      {:ok, %{"status" => "succeeded", "output" => output}} ->
        {:ok, output}

      {:ok, %{"status" => "failed", "error" => error}} ->
        {:error, error}

      {:ok, other} ->
        {:error, "Unexpected task status: #{inspect(other)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp base_req do
    Req.new(
      headers: [
        {"Authorization", "Bearer " <> System.get_env("RUNWAY_API_KEY")},
        {"Content-Type", "application/json"},
        {"X-Runway-Version", @runway_version}
      ],
      receive_timeout: 120_000
    )
  end
end
