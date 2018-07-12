defmodule Flight.DataTransformation do
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
end
