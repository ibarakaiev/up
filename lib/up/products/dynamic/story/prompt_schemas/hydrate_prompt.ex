defmodule Up.Products.Dynamic.Story.PromptSchemas.HydratePrompt do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @primary_key false
  embedded_schema do
    field :prompt, :string
  end

  def validate_changeset(changeset, _opts \\ []) do
    changeset
    |> Ecto.Changeset.validate_length(:prompt, max: 1000)
  end

  def prompt(%{story: story, prompt: prompt}) do
    [
      %{
        role: "system",
        content: """
        You are an AI assistant designed to enhance image model prompts with descriptions of characters.

        You are given a prompt with placeholders such as PERSON ONE and PERSON TWO, as well as descriptions of these two people, and your job is to rewrite the prompt with these descriptions while preserving all the information in the original 
        """
      },
      %{
        role: "user",
        content: """
        Replace the following prompt with the description of the two people:

        -- PROMPT --
        #{prompt}
        -- END PROMPT --

        -- PERSON ONE --
        #{story.person_one_description}
        -- END PERSON ONE --

        -- PERSON TWO --
        #{story.person_two_description}
        -- END PERSON TWO --

        If a prompt explicitly mentions clothes such as a wedding dress, do not incorporate new clothes into the description. Otherwise, mention clothes. Make sure to mention the person's WEIGHT.
        """
      }
    ]
  end

  def example(_params) do
    {:ok,
     %__MODULE__{
       prompt: "A friendly dragon"
     }}
  end
end
