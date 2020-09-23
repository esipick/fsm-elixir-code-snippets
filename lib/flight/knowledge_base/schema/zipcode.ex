defmodule Flight.KnowledgeBase.ZipCode do
    use Ecto.Schema, warn: false
    import Ecto.Changeset

    alias Flight.KnowledgeBase.ZipCode

    @primary_key false
    schema "zip_codes" do
        field :zip_code, :string, primary_key: true

        field :city, :string, null: false
        
        field :state, :string, null: false
        field :state_abbrv, :string, null: false

        field :country, :string, null: false

        timestamps([inserted_at: :created_at])
    end

    defp required_fields(), do: ~w(zip_code city state state_abbrv country)a

    def changeset(%ZipCode{} = changeset, params \\ %{}) do
        changeset
        |> cast(params, __MODULE__.__schema__(:fields))
        |> validate_required(required_fields())
    end
end