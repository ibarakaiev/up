defmodule UpWeb.Live.Products.Dynamic.Story.New do
  @moduledoc false
  use UpWeb, :live_view

  alias Up.Products.Dynamic.Story
  alias Up.Services.S3
  alias Up.Engine

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-screen-sm">
      <h1 class="text-3xl font-bold">Generate a story</h1>
      <p class="mt-6">
        Welcome to the story generator in the style of Up! To proceed, please upload an image of the couple for whom you want to generate the story. The image must clearly show faces of only two people.
      </p>
      <.simple_form for={@form} multipart phx-submit="submit" phx-change="validate">
        <.live_file_input upload={@uploads.couple} />
        <section phx-drop-target={@uploads.couple.ref}>
          <%!-- render each couple entry --%>
          <article :for={entry <- @uploads.couple.entries} class="upload-entry">
            <figure>
              <.live_img_preview entry={entry} />
              <figcaption>{entry.client_name}</figcaption>
            </figure>

            <%!-- entry.progress will update automatically for in-flight entries --%>
            <progress value={entry.progress} max="100">{entry.progress}%</progress>

            <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>

            <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
            <p :for={err <- upload_errors(@uploads.couple, entry)} class="alert alert-danger">
              {error_to_string(err)}
            </p>
          </article>

          <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
          <p :for={err <- upload_errors(@uploads.couple)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
        </section>

        <:actions>
          <.button>Upload</.button>
        </:actions>
        <p if={@error} class="text-red-900 italic text-sm mt-6">{@error}</p>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:couple, accept: ~w(.jpg .jpeg .png))
     |> assign(%{
       form: AshPhoenix.Form.for_create(Story, :create) |> to_form()
     })
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", _params, socket) do
    [url] =
      consume_uploaded_entries(socket, :couple, fn %{path: path}, entry ->
        hash = Up.Utils.random_string(12)
        extension = MIME.extensions(entry.client_type) |> List.first()

        {:ok, S3.upload_from_path!("couples/#{hash}.#{extension}", path)}
      end)

    result =
      case Engine.generate_text(Story.PromptSchemas.CoupleDescription, %{image_url: url}) do
        {:ok,
         %{
           allowed: true,
           person_one_description: person_one_description,
           person_two_description: person_two_description
         }} ->
          Story.create_with_description(%{
            person_one_description: person_one_description,
            person_two_description: person_two_description,
            couple_image_url: url
          })

        {:ok, %{allowed: false, reason: reason}} ->
          {:error, reason}
      end

    case result do
      {:ok, story} ->
        {:noreply, push_navigate(socket, to: ~p"/stories/#{story.hash}")}

      {:error, reason} ->
        {:noreply,
         assign(socket, error: "The image is not allowed for the following reason: #{reason}")}
    end
  end

  #
  # def handle_event("validate", %{"form" => form_params} = _params, socket) do
  #   {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, form_params))}
  # end
  #
  # def handle_event("submit", %{"form" => form_params} = _params, socket) do
  #   case AshPhoenix.Form.submit(socket.assigns.form, params: form_params) do
  #     {:ok, memory_trivia} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Saved answers")
  #        |> push_navigate(to: ~p"/products/memory-trivia/#{memory_trivia.hash}/add-name")}
  #
  #     {:error, form} ->
  #       {:noreply, assign(socket, form: form)}
  #   end
  # end
  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
