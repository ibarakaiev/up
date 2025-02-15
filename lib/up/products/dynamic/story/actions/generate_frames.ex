defmodule Imaginara.Products.Dynamic.Book.Actions.AddStorylineQuestion do
  @moduledoc false
  use Ash.Resource.ManualUpdate

  alias Imaginara.Products.Dynamic.Book

  @impl true
  def update(changeset, _opts, _context) do
    book = changeset.data

    %{"hash" => book.hash}
    |> Workers.Export.new()
    |> Oban.insert!()

    {:ok, book}
  end
end
