defmodule Up.Products do
  use Ash.Domain,
    otp_app: :up

  resources do
    resource Up.Products.Dynamic.Story
    resource Up.Products.Dynamic.Story.Frame
  end
end
