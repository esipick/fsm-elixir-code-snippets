defmodule Flight.MonthlyCourseInvoiceJob do
  require Ecto.Query
  require Logger
  import Ecto.Query
  alias Flight.Accounts.User
  def get_number_of_courses_to_bill(courses)do
    Enum.reduce(courses, 0, fn course, acc ->

      today = DateTime.utc_now
      courseCreateDate  =   course.created_at |> DateTime.from_unix!() |> DateTime.to_naive()
      #Logger.info fn -> "courseCreateDate: #{inspect courseCreateDate}" end
      if today.month == courseCreateDate.month do
         1 + acc
      else
        0 + acc
      end
    end)
  end
  def send_course_monthly_invoice() do
    #Logger.info("MonthlyCourseInvoiceJob:send_course_monthly_invoice -- Started...")
    today = DateTime.utc_now
    list_items = FlightWeb.Admin.SchoolListItem.items_from_schools(Flight.Accounts.get_schools())
    for school_item <- list_items do
      #check if monthly course invoice is created in this month.
      currentMonthCourseAdminInvoice =  Fsm.Billing.Invoices.getCurrentMonthCourseAdminInvoice(school_item.school.id)
      case currentMonthCourseAdminInvoice != nil && currentMonthCourseAdminInvoice.inserted_at.month ==  today.month  do
        true->
          Logger.info fn -> "Invoice already created for School #{school_item.school.name} (id: #{school_item.school.id}) for Month of #{today.month}" end
        false->
          courses = Flight.General.get_school_lms_courses(school_item.school.id)
          number_on_course_to_bill = get_number_of_courses_to_bill(courses)
          per_course_price = Application.get_env(:flight, :per_course_price)*100
          total_amount_to_bill = number_on_course_to_bill * per_course_price

          if number_on_course_to_bill == 0 do
            Logger.info fn -> "Invoice not send for School #{school_item.school.name} (id: #{school_item.school.id}), because there are #{number_on_course_to_bill} number of courses." end
          else
            #get admin user info using admin email
            case user = Flight.Accounts.get_user_by_email(school_item.school.contact_email) do
              %User{archived: false} ->
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

                invoice_resp = Fsm.Billing.create_invoice(create_invoice_item, false, school_item.school.id, Application.get_env(:flight, :monthly_invoice_creator))
              #Logger.info fn -> "Invoice created for School #{school_item.school.name} (id: #{school_item.school.id}) for Month of #{today.month}. Number of #{number_on_course_to_bill} courses billed to school admin #{user.email}}" end
              _ ->
                Logger.info fn -> "Invoice not send for School #{school_item.school.name} (id: #{school_item.school.id}), because School admin #{school_item.school.contact_email} account does not exist." end
            end
          end

      end
    end
    Logger.info("MonthlyCourseInvoiceJob:send_course_monthly_invoice -- Ended...")
  end
end
