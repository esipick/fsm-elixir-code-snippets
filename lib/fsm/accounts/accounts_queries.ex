defmodule Fsm.Accounts.UserQueries do
    @moduledoc false
  
    import Ecto.Query, warn: false
  
    alias Fsm.Accounts.User
    alias Fsm.Accounts.UserRole
  
    def get_user(user_id) do
      from u in User,
      select: u,
      where: u.id == ^user_id
    end

    def get_user_with_roles(user_id) do
        from u in User,
            inner_join: ur in UserRole, on: u.id == ur.user_id,
            select: %{email: u.email,
            date_of_birth: u.date_of_birth,
            gender: u.gender,
            emergency_contact_no: u.emergency_contact_no,
            d_license_no: u.d_license_no,
            d_license_expires_at: u.d_license_expires_at,
            d_license_state: u.d_license_state,
            passport_no: u.passport_no,
            passport_expires_at: u.passport_expires_at,
            passport_country: u.passport_country,
            passport_issuer_name: u.passport_issuer_name,
            last_faa_flight_review_at: u.last_faa_flight_review_at,
            renter_policy_no: u.renter_policy_no  ,      
            first_name: u.first_name,
            last_name: u.last_name,
            school_id: u.school_id,
            roles: fragment("array_agg(?)", ur.role_id)},
            group_by: u.id,
            where: u.id == ^user_id
    end

  end