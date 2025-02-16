defmodule Up.Products.Dynamic.Story.PromptSchemas.CheckImage do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @primary_key false
  embedded_schema do
    field :matches_requirements, :boolean

    field :explanation, :string

    field :safe, :boolean
  end

  def prompt(%{prompt: prompt, image_url: image_url}) do
    [
      %{
        role: "system",
        content: """
        Your task is to verify that the provided AI-generated image matches the requirements.

        IMPORTANT: Set the 'safe' field to false if you detect any inappropriate or unsafe content in the provided input or in the generated output. Otherwise, set it to true.
        """
      },
      %{
        role: "user",
        content: [
          %{
            type: "text",
            text: """
            Verify that the provided image matches the following prompt:

            #{prompt}

            If the requirements are not met, return an explanation. Otherwise, leave it empty.

            Make sure the image is not weird and is physically consistent. There may not be transparent bodies, flying limbs, flying weird things, etc. Make sure the body weight matches the description, if provided. Make sure the genders are correct, if appropriate.

            If eye colors don't match that's fine. Minor age differences are also fine.

            Make sure there's no captioned text.
            """
          },
          %{
            type: "image_url",
            image_url: %{url: "#{image_url}"}
          }
        ]
      }
    ]
  end

  def example(_params) do
    {:ok,
     %__MODULE__{
       matches_requirements: true,
       safe: true
     }}
  end
end
