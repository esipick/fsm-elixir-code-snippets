defmodule FlightWeb.API.InspectionController do
  use FlightWeb, :controller
  alias Flight.Curriculum
  alias Flight.General, as: Course
  alias Fsm.Inspections
  alias Fsm.Scheduling.Aircraft
  alias Flight.Repo
  alias Fsm.Aircrafts.Inspection

  def create(%{assigns: %{current_user: %{id: user_id}}} = conn, %{
    "document" => document,
  }) do

    IO.inspect(document, label: "document----")
    attachments = Map.get(document, "attachments") || []
    inspection_id = Map.get(document, "inspection_id")
    note = Map.get(document, "note")
    next_inspection_tach_time = Map.get(document, "next_inspection_tach_time")
    next_inspection_date = Map.get(document, "next_inspection_date")
    is_repeated = Map.get(document, "is_repeated")
    is_repeated = case is_repeated == "true" do
      true->
        true
      false->
        false
    end
    {inspection_id, _} = Integer.parse(inspection_id)
    IO.inspect(attachments, label: "attachments----")
    complete_inspection_data =
      %{
      inspection_id: inspection_id,
      tach_hours: next_inspection_tach_time,
      next_inspection: next_inspection_date,
      is_repeated: is_repeated,
      note: note
    }
    inspection = Repo.get_by(Inspection, id: inspection_id)
    IO.inspect(inspection, label: "inspection----")
   can_update_inspection =  case inspection.date_tach == :tach and next_inspection_tach_time != "" do
      true->
        aircraft = Repo.get_by(Aircraft, id: inspection.aircraft_id)
        last_tach_time = aircraft.last_tach_time
        IO.inspect(last_tach_time, label: "last_tach_time----")
        {next_inspection_tach_time, _} = Float.parse(next_inspection_tach_time)
        converted_last_inspection_time = Flight.Format.tenths_from_hours(next_inspection_tach_time)
        case converted_last_inspection_time <=  last_tach_time do
          true ->
            conn
            |> put_status(500)
            |> json(%{error: "Last inspection tach value should be greater than current inspection tach value"})
          false ->
           true
        end
      _->
        true
    end
    case can_update_inspection do
      true->
        case attachments do
          []->
            Inspections.complete_inspection(complete_inspection_data)
            conn
            |> put_status(200)
            |> json(document)
          _->
            Fsm.AttachmentUploader.upload_files_to_s3(inspection_id, attachments)
            |> case do
                 {:error, msg} ->
                   conn
                   |> put_status(500)
                   |> json(%{error: msg})
                 {:ok, attachments} ->
                   attachments =
                     Enum.map(attachments, fn attach ->
                       attach
                       |> Map.put(:attachment_type, :inspection)
                       |> Map.put(:user_id, user_id)
                       |> Map.put(:inspection_id, inspection_id)
                     end)
                   IO.inspect(attachments, label: "attachments----666")
                   Inspections.add_multiple_inspection_images(attachments)
                   |> case do
                        {:error, error} ->
                          conn
                          |> put_status(500)
                          |> json(%{error: "Couldn't create inspection attachment. Please try again"})
                        {:ok, _attachments_changeset} ->
                          Inspections.complete_inspection(complete_inspection_data)
                          conn
                          |> put_status(200)
                          |> json(%{ attachments: attachments})
                      end

               end
        end
      _->
        false
    end

  end



end
