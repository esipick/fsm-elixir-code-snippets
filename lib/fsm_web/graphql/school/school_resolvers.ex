defmodule FsmWeb.GraphQL.School.SchoolResolvers do
    alias Fsm.School
  
    require Logger

    def get_school(parent, _args, %{context: %{current_user: %{school_id: school_id}}}=context) do
      School.get_school(school_id)
    end
  end
    