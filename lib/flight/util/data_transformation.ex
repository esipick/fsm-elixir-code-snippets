defmodule Flight.DataTransformation do
  alias Flight.{Repo, Scheduling}
  require Ecto.Query
  import Ecto.Query

  def migrate_all_records_to_randon_aviation(true = _are_you_sure?) do
    Flight.Repo.transaction(fn ->
      school = Flight.Repo.insert!(%Flight.Accounts.School{name: "Randon Aviation"})

      Flight.Repo.update_all(Flight.Scheduling.Aircraft, set: [school_id: school.id])
      Flight.Repo.update_all(Flight.Scheduling.Appointment, set: [school_id: school.id])
      Flight.Repo.update_all(Flight.Accounts.Invitation, set: [school_id: school.id])
      Flight.Repo.update_all(Flight.Accounts.User, set: [school_id: school.id])
      Flight.Repo.update_all(Flight.Billing.Transaction, set: [school_id: school.id])
      Flight.Repo.update_all(Flight.Curriculum.ObjectiveNote, set: [school_id: school.id])
      Flight.Repo.update_all(Flight.Curriculum.ObjectiveScore, set: [school_id: school.id])
    end)
  end

  def migrate_appointments_to_walltime(true = _are_you_sure?) do
    Repo.transaction(fn ->
      schools = Repo.all(Flight.Accounts.School)

      for school <- schools do
        appointments =
          from(a in Scheduling.Appointment, where: a.school_id == ^school.id)
          |> Repo.all()

        for appointment <- appointments do
          appointment
          |> Scheduling.Appointment.changeset(%{
            start_at: Flight.Walltime.utc_to_walltime(appointment.start_at, school.timezone),
            end_at: Flight.Walltime.utc_to_walltime(appointment.end_at, school.timezone)
          })
          |> Repo.update!()
        end
      end
    end)
  end

  def add_type_to_transaction_line_items(true = _are_you_sure?) do
    alias Flight.Billing.TransactionLineItem

    Repo.transaction(fn ->
      line_items =
        TransactionLineItem
        |> Repo.all()
        |> Repo.preload(:transaction)

      Enum.map(line_items, fn item ->
        type =
          cond do
            item.aircraft_id ->
              "aircraft"

            item.instructor_user_id ->
              "instructor"

            item.transaction.type == "debit" ->
              cond do
                item.transaction.paid_by_balance ->
                  "remove_funds"

                true ->
                  "custom"
              end

            item.transaction.paid_by_charge ->
              "add_funds"

            !item.transaction.paid_by_balance ->
              "credit"

            true ->
              Repo.rollback("Unknown categorization: #{inspect(item)}")
          end

        item
        |> TransactionLineItem.changeset(%{type: type})
        |> Repo.update!()
      end)
    end)
  end
end
