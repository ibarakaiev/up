defmodule Up.Products.Dynamic.Story do
  @moduledoc false
  use Ash.Resource,
    otp_app: :up,
    domain: Up.Products,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  postgres do
    table "stories"
    repo Up.Repo
  end

  state_machine do
    initial_states([:initialized])
    default_initial_state(:initialized)
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
  end
end
