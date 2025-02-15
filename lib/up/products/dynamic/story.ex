defmodule Up.Products.Dynamic.Story do
  @moduledoc false
  use Ash.Resource,
    otp_app: :up,
    domain: Up.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__.Actions

  postgres do
    table "stories"
    repo Up.Repo
  end

  state_machine do
    initial_states [:initialized]
    default_initial_state :initialized
  end

  code_interface do
    domain Up.Products

    define :create, action: :create
    define :create_with_description, action: :create_with_description
    define :read_all, action: :read
    define :get_by_id, action: :by_id, args: [:id]
    define :get_by_hash, action: :by_hash, args: [:hash]
    define :update, action: :update
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :create_with_description do
      accept [:hash, :person_one_description, :person_two_description, :couple_image_url]
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false

      get? true

      filter expr(id == ^arg(:id))
    end

    read :by_hash do
      argument :hash, :string, allow_nil?: false

      get? true

      filter expr(hash == ^arg(:hash))
    end

    update :collect_image do
      argument :couple_image_url, :string, allow_nil?: false

      change atomic_update(:couple_image_url, expr(^arg(:couple_image_url)))
    end

    update :generate_frames do
      manual Actions.GenerateFrames
    end
  end

  pub_sub do
    module UpWeb.Endpoint

    prefix "story"

    publish_all :update, ["updated", :id]
  end

  attributes do
    uuid_primary_key :id

    attribute :hash, :string,
      allow_nil?: false,
      default: fn -> Up.Utils.random_string(12) end,
      public?: true

    attribute :couple_image_url, :string, public?: true
    attribute :person_one_description, :string, public?: true
    attribute :person_two_description, :string, public?: true
  end

  relationships do
    has_many :frames, __MODULE__.Frame
  end
end
