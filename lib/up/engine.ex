defmodule Up.Engine do
  @moduledoc false
  @callback generate_text(prompt_schema :: term, params :: map, opts :: [keyword]) ::
              {:ok, term} | {:error, term}
  @callback generate_image(prompt :: term, opts :: [keyword]) ::
              {:ok, term} | {:error, term}
  @callback generate_video(prompt_image :: term, prompt_text :: term, opts :: [keyword]) ::
              {:ok, term} | {:error, term}

  @module Application.compile_env!(:up, :engine)

  defdelegate generate_text(prompt_schema, params, opts \\ []), to: @module
  defdelegate generate_image(prompt, opts \\ []), to: @module
  defdelegate generate_video(prompt_image, prompt_text, opts \\ []), to: @module
end
