defmodule Up.Repo.Migrations.AddPeopleDescriptions do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:stories) do
      add :person_one_description, :text
      add :person_two_description, :text
    end
  end

  def down do
    alter table(:stories) do
      remove :person_two_description
      remove :person_one_description
    end
  end
end
