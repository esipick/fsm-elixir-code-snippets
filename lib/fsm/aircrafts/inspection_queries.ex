defmodule Fsm.Aircrafts.InspectionQueries do
    import Ecto.Query, warn: false
    import Ecto.SoftDelete.Query

    alias Fsm.Accounts.User
    alias Fsm.Scheduling.Aircraft
    alias Fsm.Aircrafts.Inspection
    alias Fsm.Aircrafts.InspectionData
    alias Fsm.Aircrafts.Engine

    def get_user_inspection_query(user_id, inspection_id) do
        from u in User,
            inner_join: a in Aircraft, on: a.user_id == u.id,
            inner_join: i in Inspection, on: i.aircraft_id == a.id,
            select: u,
            where: i.id == ^inspection_id and u.id == ^user_id
    end


    @doc """
    Returns query to find pending notifications for user
    """
    def get_upcoming_inspections_query(user_id) do
        from d in InspectionData,
            inner_join: i in Inspection, on: i.id == d.inspection_id
                and i.is_completed == false
                and i.is_notified == false,
            inner_join: a in Aircraft, on: a.id == i.aircraft_id
                and a.user_id == ^user_id,
            select: {i, d},
            where: d.class_name == "next_inspection" and not is_nil(d.t_date)
    end

    @doc """
    Returns query to find pending date inspection push notifications of all users
    """
    def get_upcoming_date_inspections_to_be_push_notified_query do
        from id in InspectionData,
            inner_join: i in Inspection,
                on: i.id == id.inspection_id and
                    i.is_completed == false and
                    i.is_notified == false,
            inner_join: a in Aircraft,
                on: a.id == i.aircraft_id,
            inner_join: u in User,
                on: a.user_id == u.id,
            select: %{inspection: i, inspection_data: id, aircraft: a, user: u},
            where: id.class_name == "next_inspection" and not is_nil id.t_date
    end

    @doc """
    Returns query to find pending tach inspection push notifications of all users
    """
    def get_upcoming_tach_inspections_to_be_push_notified_query do
        from id in InspectionData,
            inner_join: i in Inspection,
                on: i.id == id.inspection_id and
                    i.is_completed == false and
                    i.is_notified == false,
            inner_join: a in Aircraft,
                on: a.id == i.aircraft_id,
            inner_join: u in User,
                on: a.user_id == u.id,
            inner_join: ae in Engine,
                on: ae.aircraft_id == a.id and
                    id.t_float >= ae.engine_tach_start and
                    id.t_float <= (ae.engine_tach_start + s.tach_hours_before),
            select: %{inspection: i, inspection_data: id, user: u, aircraft: a, aircraft_engine: ae},
            where: id.class_name == "next_inspection" and not is_nil id.t_float
    end

    @doc """
    Returns query to find pending date inspection email notifications of all users
    """
    def get_upcoming_date_inspections_to_be_email_notified_query do
        from id in InspectionData,
            inner_join: i in Inspection,
                on: i.id == id.inspection_id and
                    i.is_completed == false and
                    i.is_email_notified == false,
            inner_join: a in Aircraft,
                on: a.id == i.aircraft_id,
            inner_join: u in User,
                on: a.user_id == u.id,
            select: %{inspection: i, inspection_data: id, aircraft: a, user: u},
            where: id.class_name == "next_inspection" and not is_nil id.t_date
    end

    @doc """
    Returns query to find pending tach inspection email notifications of all users
    """
    def get_upcoming_tach_inspections_to_be_email_notified_query do
        from id in InspectionData,
            inner_join: i in Inspection,
                on: i.id == id.inspection_id and
                    i.is_completed == false and
                    i.is_email_notified == false,
            inner_join: a in Aircraft,
                on: a.id == i.aircraft_id,
            inner_join: u in User,
                on: a.user_id == u.id,
            inner_join: ae in Engine,
                on: ae.aircraft_id == a.id and
                    id.t_float >= ae.engine_tach_start and
                    id.t_float <= (ae.engine_tach_start + s.tach_hours_before),
            select: %{inspection: i, inspection_data: id, user: u, aircraft: a, aircraft_engine: ae},
            where: id.class_name == "next_inspection" and not is_nil id.t_float
    end
end
