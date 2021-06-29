defmodule FsmWeb.GraphQL.Errors do
    @moduledoc """
    Defines common GraphQL error responses
    """
    defmacro __using__(_) do
        quote do
            @invalid_login {
                :error,
                %{
                    code: :invalid_login,
                    message: "Incorrect email or password"
                }
            }

            @permission_denied {
                :error,
                %{
                    code: :permission_denied,
                    message: "Permission denied"
                }
            }

            @not_found {
                :error,
                %{
                    code: :not_found,
                    message: "Not found"
                }
            }

            @not_authenticated {
                :error,
                %{
                    code: :not_authenticated,
                    message: "Not authenticated"
                }
            }

            @invalid_token {
                :error,
                %{
                    code: :invalid_token,
                    message: "Invalid token"
                }
            }
        end
    end
end