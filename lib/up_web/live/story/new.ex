defmodule UpWeb.Live.Products.Dynamic.Story.New do
  @moduledoc false
  use UpWeb, :live_view

  alias Up.Products.Dynamic.Story
  alias Up.Services.S3
  alias Up.Engine

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-lg p-6">
      <h1 class="text-3xl font-bold mb-4">Generate a Story</h1>
      <p class="text-gray-700 mb-6">
        Welcome to the story generator in the style of Up! To proceed, please upload an image of the couple for whom you want to generate the story. The image must clearly show the faces of only two people.
      </p>
      <.simple_form for={@form} multipart phx-submit="submit" phx-change="validate">
        <!-- Styled file input with a dropzone -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">Couple Image</label>
          <div
            class="relative flex items-center justify-center w-full border-2 border-dashed border-gray-300 rounded-md p-6 text-center cursor-pointer hover:border-blue-500 transition"
            phx-drop-target={@uploads.couple.ref}
          >
            <span class="text-gray-500">Drag and drop your image here or click to select</span>
            <.live_file_input
              upload={@uploads.couple}
              class="absolute inset-0 opacity-0 cursor-pointer"
            />
          </div>
        </div>
        
    <!-- Previews and progress for uploaded images -->
        <div class="mb-6 grid grid-cols-2 gap-4">
          <%= for entry <- @uploads.couple.entries do %>
            <article class="flex flex-col items-center p-2 border rounded-md">
              <figure class="w-20 h-20 mb-2">
                <.live_img_preview entry={entry} class="object-cover w-full h-full rounded-md" />
              </figure>
              <figcaption class="text-xs text-gray-600 truncate">{entry.client_name}</figcaption>
              <progress
                value={entry.progress}
                max="100"
                class="w-full mt-1 h-2 rounded-full overflow-hidden"
              >
                {entry.progress}%
              </progress>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
                class="mt-1 text-red-500 hover:text-red-700"
              >
                &times;
              </button>
              <%= for err <- upload_errors(@uploads.couple, entry) do %>
                <p class="text-xs text-red-600 mt-1">{error_to_string(err)}</p>
              <% end %>
            </article>
          <% end %>
          <%= for err <- upload_errors(@uploads.couple) do %>
            <p class="col-span-2 text-xs text-red-600">{error_to_string(err)}</p>
          <% end %>
        </div>

        <:actions>
          <.button
            phx-disable-with="Uploading..."
            class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 rounded-md transition"
          >
            Upload and Generate Story
          </.button>
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

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:too_many_files), do: "Too many files selected"
  defp error_to_string(:not_accepted), do: "Unacceptable file type"
end
