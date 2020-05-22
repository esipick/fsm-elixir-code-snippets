defmodule Flight.Billing.LineItemCreator do
  def populate_creator(line_items, current_user) do
    Enum.map(line_items, fn line_item ->
      case line_item["creator_id"] do
        empty when empty in [nil, 0] -> Map.put(line_item, "creator_id", current_user.id)
        _ -> line_item
      end
    end)
  end
end
