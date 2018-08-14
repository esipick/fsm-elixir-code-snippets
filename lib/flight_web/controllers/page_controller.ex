defmodule FlightWeb.PageController do
  use FlightWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/admin/login")
  end
  
  def forgot(conn, _) do
    render(conn, "forgot_password.html")
  end
  
  def reset(conn, _) do
    render(conn, "reset_password.html")
  end  
  
end

