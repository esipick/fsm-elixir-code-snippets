defmodule Flight.General do
  def getLSMLoginUrl(school,user) do
    webtoken = Application.get_env(:flight, :webtoken_key) <> "_" <>  to_string(school.id)
               |>  Flight.Webtoken.encrypt
    encodedWebtoken = Base.encode64(webtoken)

    Application.get_env(:flight, :lms_endpoint) <> "/auth/fsm2moodle/user_mgt.php?action=login&webtoken=" <> encodedWebtoken <> "&email=" <> user.email <> "&username=" <> user.email <> "&userid=" <> to_string(user.id) <> "&role=catmanager&firstname=" <> user.first_name <> "&lastname=" <> user.last_name <> "&courseid=0"
    end
end
