defmodule Flight.Billing.InvoiceCustomLineItem do
  use Ecto.Schema
  import Flight.Repo
  import Ecto.Changeset

  alias __MODULE__

  @reserved_descriptions ["Flight Hours", "Instructor Hours"]
  @required_fields ~w(default_rate description taxable school_id)a

  schema "invoice_custom_line_items" do
    field(:default_rate, :integer)
    field(:description, :string)
    field(:taxable, :boolean, default: false)

    belongs_to(:school, Flight.Accounts.School)

    timestamps()
  end

  def changeset(%InvoiceCustomLineItem{} = custom_line_item, attrs) do
    custom_line_item
    |> base_validates(attrs, @required_fields)
  end

  def create_custom_line_item(params, school_id) do
    %InvoiceCustomLineItem{school_id: id_from_string(school_id)}
    |> changeset(params)
    |> insert()
  end

  def delete_custom_line_item(id, school_id) do
    custom_line_item =
      get_by(InvoiceCustomLineItem, %{
        id: id_from_string(id),
        school_id: id_from_string(school_id)
      })

    if custom_line_item, do: delete(custom_line_item)
  end

  def update_custom_line_item(params, id, school_id) do
    %InvoiceCustomLineItem{id: id_from_string(id), school_id: id_from_string(school_id)}
    |> changeset(params)
    |> update()
  end

  defp id_from_string(id), do: String.to_integer(id)

  defp base_validates(changeset, attrs, fields) do
    changeset
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> validate_inclusion(:default_rate, -999_999..999_999, message: "must be less than 10,000")
    |> validate_exclusion(:description, @reserved_descriptions)
    |> unique_constraint(:description,
      name: :invoice_custom_line_items_description_school_id_index
    )
  end
end
