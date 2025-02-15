defmodule Up.Services.S3 do
  @moduledoc false

  def put!(key, body, opts \\ []) do
    content_length = Keyword.get(opts, :content_length)

    content_length =
      case {content_length, body} do
        {nil, binary} when is_binary(binary) ->
          byte_size(binary)

        {nil, _stream} ->
          raise ArgumentError, "content_length option is required for streaming bodies"

        {length, _} ->
          length
      end

    headers = [
      {"content-length", Integer.to_string(content_length)} | Keyword.get(opts, :headers, [])
    ]

    Req.put!(
      base_req(),
      url: key,
      body: body,
      headers: headers
    )

    "#{System.get_env("AWS_ENDPOINT_URL_S3")}/#{System.get_env("BUCKET_NAME")}/#{key}"
  end

  def upload_from_url!(key, url) do
    {:ok, response} = Req.get(url)

    put!(key, response.body)

    "#{System.get_env("AWS_ENDPOINT_URL_S3")}/#{System.get_env("BUCKET_NAME")}/#{key}"
  end

  def get!(key), do: Req.get!(base_req(), url: key).body

  def delete!(key), do: Req.delete!(base_req(), url: key)

  defp base_req do
    Req.new(
      base_url: System.get_env("AWS_ENDPOINT_URL_S3") <> "/" <> System.get_env("BUCKET_NAME"),
      aws_sigv4: [
        access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
        secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
        region: System.get_env("AWS_REGION"),
        service: :s3
      ]
    )
  end
end
