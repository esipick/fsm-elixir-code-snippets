defmodule FsmWeb.GraphQL.Aircrafts.InspectionsResolvers do
  use FsmWeb.GraphQL.Errors
  alias Fsm.Inspections
  alias FsmWeb.GraphQL.EctoHelpers
  require Logger

  @doc """
  Get active aircraft inspections
  """
  def get_inspections(_parent, %{aircraft_id: aircraft_id} = args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)
    filter = Map.get(args, :filter) || %{}

    filter =
      case Map.has_key?(filter, :completed) do
        true ->
          filter

        false ->
          filter = filter |> Map.put(:completed, false)
      end

    case Inspections.get_inspections(aircraft_id, page, per_page, filter) do
      nil ->
        @not_found

      inspections ->
        {:ok, inspections}
    end
  end

  def get_inspections(_, _, _), do: @not_authenticated

  @doc """
  Get inspection
  """
  def get_inspection(_parent, %{inspection_id: inspection_id} = args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    case Inspections.get_inspection_by_inspection_id(inspection_id) do
      nil ->
        @not_found

      inspection ->
        {:ok, inspection}
    end
  end

  def get_inspection(_, _, _), do: @not_authenticated

  @doc """
  Update inspection data
  """
  def update_inspection(_parent, %{id: id, data: data}, %{context: %{current_user: current_user}}) do
    case Inspections.update_inspection(id, %{user_id: current_user.id}, data) do
      {:ok, _updated_record} ->
        {:ok, true}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_inspection(_parent, _args, _context), do: @not_authenticated

  def complete_inspection(_parent, args, %{context: %{current_user: current_user}}) do
    EctoHelpers.action_wrapped(fn ->
      Inspections.complete_inspection(args.completion_input)
    end)
  end

  def complete_inspection(_parent, _args, _context), do: @not_authenticated

  @doc """
  add inspection data
  """
  def add_inspection(_parent, args, %{context: %{current_user: current_user}}) do
    EctoHelpers.action_wrapped(fn ->
      Inspections.add_inspection(args.inspection_input, current_user)
    end)
  end

  def add_inspection(_parent, _args, _context), do: @not_authenticated

  @doc """
  delete inspection
  """
  def delete_inspection(_parent, %{id: id}, %{context: %{current_user: current_user}}) do
    EctoHelpers.action_wrapped(fn ->
      case Inspections.get_user_custom_inspection_query(id) do
        nil ->
          {:error, "Inspection not found or trying to delete system defined inspection."}

        inspection ->
          Inspections.delete_inspection(inspection)
      end
    end)
  end

  def delete_inspection(_parent, _args, _context), do: @not_authenticated
end
