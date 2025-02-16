defmodule Up.Products.Dynamic.Story.PromptSchemas.CoupleDescription do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @primary_key false
  embedded_schema do
    field :person_one_description, :string
    field :person_two_description, :string

    field :allowed, :boolean
    field :reason, :string
  end

  def validate_changeset(changeset, _opts \\ []) do
    changeset
    |> Ecto.Changeset.validate_length(:person_one_description, max: 400)
    |> Ecto.Changeset.validate_length(:person_two_description, max: 400)
  end

  def prompt(%{image_url: image_url}) do
    [
      %{
        role: "system",
        content: """
        You are an AI assistant designed to create textual description of a couple.

        You receive an image and verify that it clearly contains a couple that is two people. If so, you write a detailed description of each of the two people in the couple.

        Make sure to be detailed enough so that an illustrator is able to draw these people as characters in a storybook.

        IMPORTANT: Set the 'allowed' field to false if you detect any inappropriate, unsafe, or disallowed content in the generated output, and write the reason for it. Otherwise, set it to true, and keep the reason as null.
        """
      },
      %{
        role: "user",
        content: [
          %{
            type: "text",
            text: """
            Write a description of each of the people in the couple that's displayed in this image. If there are not exactly two main people in the image, you mark the image as disallowed. Note that it's fine to be background surroundings, other people in the background, as long as there are clearly exactly two people who are a couple.

            Only focus on their faces, hair, and height.

            Make sure to include the following:
            - eye color (if visible)
            - gender (as appearing)
            - hair color
            - hair style
            - hair length
            - skin color
            - eye shape
            - face shape
            - weight
            - clothes
            - and anything else that's relevant, such as glasses, freckles, etc (don't mention their absence though, only mention them if they're present)

            If one person is taller than the other, mention that they are taller, and mention that the other one is shorter.
            """
          },
          %{
            type: "image_url",
            image_url: %{url: image_url}
          }
        ]
      }
    ]
  end

  def example(_params) do
    {:ok,
     %__MODULE__{
       person_one_description: "A friendly dragon",
       person_two_description: "A talking rabbit",
       allowed: true,
       reason: nil
     }}
  end
end
