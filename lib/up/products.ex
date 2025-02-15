defmodule Up.Products do
  use Ash.Domain,
    otp_app: :up

  resources do
    resource Up.Products.Dynamic.Story
  end
end
