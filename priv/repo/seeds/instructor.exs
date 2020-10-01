
alias Flight.Accounts
alias Flight.Accounts.User

import Ecto.Query, warn: false

alias Flight.Repo

query = 
    from u in User,
        select: u,
        where: not is_nil(u.main_instructor_id)

Repo.all(query)
|> Enum.map(fn %{id: id, main_instructor_id: instructor_id} -> 
    Accounts.insert_user_instructor(id, instructor_id)
end)
