defmodule Flight.MonthlyCourseInvoiceJob do
  require Ecto.Query
  require Logger
  import Ecto.Query
  alias Flight.Accounts.User
  def get_number_of_courses_to_bill(courses)do
    Enum.reduce(courses, 0, fn course, acc ->
      Logger.info fn -> "course: #{inspect course}" end
      today = DateTime.utc_now
      courseCreateDate  =   course.created_at |> DateTime.from_unix!() |> DateTime.to_naive()
      if today.month == courseCreateDate.month do
         1 + acc
      else
        0 + acc
      end
    end)
  end
  def send_course_monthly_invoice() do
    Logger.info("MonthlyCourseInvoiceJob:send_course_monthly_invoice -- Started...")

    list_items = FlightWeb.Admin.SchoolListItem.items_from_schools(Flight.Accounts.get_schools())
    for school_item <- list_items do
      courses = Flight.General.get_school_lms_courses(school_item.school.id)
      number_on_course_to_bill = get_number_of_courses_to_bill(courses)
      per_course_price = Application.get_env(:flight, :per_course_price)*100
      total_amount_to_bill = number_on_course_to_bill * per_course_price
      Logger.info fn -> "Number of courses to bill: #{inspect number_on_course_to_bill }" end
      Logger.info fn -> "total_amount_to_bill: #{inspect total_amount_to_bill }" end
      #get admin user info using admin email
      case user = Flight.Accounts.get_user_by_email(school_item.school.contact_email) do
        %User{archived: false} ->
          Logger.info fn -> "user**************************************************************************: #{inspect user }" end
          create_invoice_item = %{
            user_id: user.id,
            date: Date.utc_today(),
            is_visible: true,
            line_items: [
              %{
                amount: abs(total_amount_to_bill),
                description: "Monthly courses invoice",
                quantity: abs(number_on_course_to_bill),
                rate: abs(per_course_price),
                taxable: false,
                type: :course_invoice,
                aircraft_id: nil,
                deductible: false
              }
            ],
            payment_option: :cc,
            status: :pending,
            tax_rate: 0,
            total: abs(total_amount_to_bill),
            total_amount_due: abs(total_amount_to_bill),
            total_tax: 0,
            is_admin_invoice: true

          }
          Logger.info fn -> "create_invoice_item: #{inspect create_invoice_item }" end
          invoice_resp = Fsm.Billing.create_invoice(create_invoice_item, false, school_item.school.id, 56)
          Logger.info fn -> "invoice_resp: #{inspect invoice_resp }" end
        _ ->
          Logger.info("Invoice not send, admin user not exist")
      end
    end
    Logger.info("MonthlyCourseInvoiceJob:send_course_monthly_invoice -- Ended...")
  end
end
