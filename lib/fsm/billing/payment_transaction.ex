defmodule Fsm.Billing.PaymentError do
    defstruct message: ""
  
    def to_message(error) do
      if is_atom(error) do
        to_string(error)
      else
        error.message
      end
    end
  end