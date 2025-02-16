defmodule Up.Products.Dynamic.Story.Frame do
  use Ash.Resource,
    otp_app: :up,
    data_layer: AshPostgres.DataLayer,
    domain: Up.Products,
    notifiers: [Ash.Notifier.PubSub]

  alias Up.Products.Dynamic.Story

  postgres do
    table "stories.frames"
    repo Up.Repo

    references do
      reference :story, on_delete: :delete
    end
  end

  code_interface do
    domain Up.Products

    define :create, action: :create
    define :update, action: :update
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end

  pub_sub do
    module UpWeb.Endpoint

    prefix "story"

    publish_all :update, ["updated", :story_id]
  end

  attributes do
    uuid_primary_key :id

    attribute :frame_number, :integer, public?: true

    attribute :image_url, :string, public?: true
  end

  relationships do
    belongs_to :story, Story do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_frame, [:story_id, :frame_number]
  end
end
