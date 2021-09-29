defmodule FlightWeb.API.AESController do
    use FlightWeb, :controller
  
    def encrypt(conn, %{"plain_text" => plain_text}) do
        cipher_text = Fsm.AES.encrypt(plain_text)
        conn
        |> put_status(200)
        |> json(%{cipher_text: cipher_text})
    end

    def decrypt(conn, %{"cipher_text" => cipher_text}) do
        plain_text = Fsm.AES.decrypt(cipher_text)
        conn
        |> put_status(200)
        |> json(%{plain_text: cipher_text})
    end
  end
  