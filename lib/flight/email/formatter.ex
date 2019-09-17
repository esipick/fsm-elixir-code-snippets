defimpl Bamboo.Formatter, for: Flight.Accounts.User do
  def format_email_address(user, _opts) do
    {user.first_name, user.email}
  end
end
