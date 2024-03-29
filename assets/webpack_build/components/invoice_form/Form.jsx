import { loadStripe } from "@stripe/stripe-js";
import classnames from 'classnames';
import http from 'j-fetch';
import { debounce } from 'lodash';
import React, { Component } from 'react';
import DatePicker from 'react-datepicker';
import Select from 'react-select';
import CreatableSelect from 'react-select/creatable';
import "regenerator-runtime/runtime";
import Error from '../common/Error';
import { addSchoolIdParam, authHeaders, isEmpty } from '../utils';
import ConfirmAlert from './ConfirmAlert';
import ConfirmHobbTachAlert from './ConfirmHobbTachAlert';
import {
  BALANCE,
  DEFAULT_GUEST_PAYMENT_OPTION,
  DEFAULT_PAYMENT_OPTION,
  DEMO_PAYMENT_OPTIONS,
  GUEST_PAYMENT_OPTIONS,
  PAYMENT_OPTIONS,
  MAINTENANCE_PAYMENT_OPTIONS,
  DEFAULT_MAINTENANCE_PAYMENT_OPTION
} from './constants';
import ErrorAlert from './ErrorAlert';
import LineItemsTable from './LineItemsTable';
import {
  containsDemoFlight,
  containsSimulator,
  isMaintenanceInvoice,
  itemsFromAppointment,
  itemsFromInvoice 
 } from './line_items/line_item_utils';
import LowBalanceAlert from './LowBalanceAlert';

let calculateRequest = () => { };

class Form extends Component {
  
  constructor(props) {
    super(props);

    this.formRef = null;
    
    const { creator, staff_member, appointment } = props;
    const demo = appointment && appointment.demo
    const appointments = appointment ? [appointment] : [];
    
    let id = localStorage.getItem('invoice_id')

    if  (id && !props.id) {
      localStorage.removeItem('invoice_id')
      window.location = `/billing/invoices/${id}/edit`;
    }
    
    this.state = {
      appointment,
      appt_status: appointment && appointment.appt_status,
      appointments,
      id: props.id || '',
      current_user_id: props.current_user_id,
      user_roles: props.user_roles,
      sales_tax: props.tax_rate || 0,
      action: props.action || 'create',
      error: props.error || '',
      errors: props.errors || {},
      stripe_error: props.stripe_error || '',
      error_alert_total_open: false,
      error_alert_total_due_open: false,
      error_alert_total_tax_open: false,
      error_date_alert_open: false,
      confirm_alert_open: false,
      balance_warning_open: false,
      hobb_tach_warning_open: false,
      hobb_tach_warning_accepted: false,
      balance_warning_accepted: false,
      payment_method: isMaintenanceInvoice(appointment) ? DEFAULT_MAINTENANCE_PAYMENT_OPTION : this.getPaymentMethod(props.payment_method, demo),
      notes: props.notes,
      payer_email: props.payer_email,
      send_receipt_email: true,
      line_items: [],
      is_visible: true,
      student: staff_member ? undefined : creator,
      date: new Date(),
      ending_hobbs_tach_error: false,
      demo
    }
  }

  componentDidMount() {
    if (this.state.id) {
      this.loadInvoice().then(() => this.loadData());
    } else {
      this.loadData();
    }
  }

  loadData = () => {
    this.loadStudents();
    this.loadAppointments();
    this.loadAircrafts();
    this.loadInstructors();
    this.loadRooms();
  }

  loadAircrafts = () => {
    return http.get({ url: '/api/aircrafts', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { 
        const simulators = r.data.filter(function(item){return item.simulator})
        const aircrafts = r.data.filter(function(item){return !item.simulator})

        this.setState({ aircrafts: aircrafts, simulators: simulators }); 
      })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  }

  loadInstructors = () => {
    return http.get({ url: '/api/users/by_role?role=instructor', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { this.setState({ instructors: r.data }); })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  }

  loadRooms = () => {
    return http.get({ url: '/api/rooms', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { this.setState({ rooms: r.data }); })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  }

  loadInvoice = () => {
    this.setState({ invoice_loading: true });

    return http.get({
      url: '/api/invoices/' + this.state.id,
      headers: authHeaders()
    }).then(r => r.json())
      .then(r => {
        const invoice = itemsFromInvoice(r.data, this.props.user_roles);
        const demo = invoice.appointment ? invoice.appointment.demo : false
        const maintenanceAppt = invoice.appointment?.type === "maintenance";
        const payment_method = maintenanceAppt ? DEFAULT_MAINTENANCE_PAYMENT_OPTION : this.getPaymentMethod(invoice.payment_option, demo)

        this.setState({
          date: invoice.date ? new Date(invoice.date) : new Date(),
          student: invoice.user || invoice.appointment?.mechanic_user || this.demoGuestPayer(demo, invoice.payer_name),
          line_items: invoice.line_items || [],
          payment_method: payment_method,
          notes: invoice.notes,
          payer_email: invoice.payer_email,
          appt_status: invoice.appt_status,
          demo: demo,
          sales_tax: invoice.tax_rate,
          total: invoice.total || 0,
          total_tax: invoice.total_tax || 0,
          total_amount_due: invoice.total_amount_due || 0,
          appointment: invoice.appointment,
          default_appointment: invoice.appointment,
          default_user: invoice.user,
          invoice_loading: false,
          is_admin_invoice: invoice.is_admin_invoice
        });
      })
      .catch(err => {
        if (err.json) {
          err.json().then(e => {
            console.warn(e);
            this.setState({ invoice_loading: false });
          });
        } else {
          console.warn(err);
          this.setState({ invoice_loading: false });
        }
      });
  }

  getPaymentMethod = (payment_option, demo = false) => {

    if(!payment_option || (payment_option === BALANCE && demo)) {
      return DEFAULT_PAYMENT_OPTION;
    }
    
    const findedOption = PAYMENT_OPTIONS.find((option) => {
      return option.value === payment_option;
    });
    
    return findedOption || DEFAULT_PAYMENT_OPTION;
  }

  setFormRef = (form) => {
    this.formRef = form;

    form.addEventListener("submit", (event) => { event.preventDefault() });
  };

  loadStudents = () => {
    if (!this.props.staff_member) return;

    return http.get({ url: '/api/users?invoice_payee', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { this.setState({ students: r.data }); })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  }

  loadAppointments = (student) => {
    if (!student) student = this.state.student;

    if (!student || student.guest) { return };
    if (this.state.appointment_loading) return;

    this.setState({ appointment_loading: true });

    http.get({
      url: '/api/invoices/appointments?user_id=' + this.getUserId(student, this.state.appointment) + addSchoolIdParam('&'),
      headers: authHeaders()
    }).then(r => r.json())
      .then(r => {
        let appointments;
        const { student, default_user, default_appointment, appointment} = this.state;

        if ((this.getUserId(student, appointment )) == (default_user && default_user.id)) {
          appointments = [default_appointment, ...r.data].filter(e => e);
        } else {
          appointments = r.data;
        }

        this.setState({ appointments, appointment_loading: false });
      })
      .catch(err => {
        err.json().then(e => {
          console.warn(e);
          this.setState({ appointment_loading: false });
        })
      });
  }

  appointmentLabel = (appointment) => {
    if (appointment) {
      const { start_at, end_at, aircraft, instructor_user } = appointment;

      const date = moment.utc(start_at).add(+(moment().utcOffset()), 'm').format('YYYY-MM-DD')
      const start_time = moment.utc(start_at).add(+(moment().utcOffset()), 'm').format('hh:mmA');
      const end_time = moment.utc(end_at).add(+(moment().utcOffset()), 'm').format('hh:mmA');
      const instructor =
        instructor_user ? `, Instructor: ${instructor_user.first_name} ${instructor_user.last_name}` : '';

      return `${date}, ${start_time} - ${end_time}${instructor}`;
    } else {
      return '';
    }
  }

  demoFlightAppointment = (appointment) => {
    const { demo } = appointment;
      return demo;
  }

  setAppointment = (appointment) => {
    const line_items = itemsFromAppointment(appointment, [], this.state.user_roles)
    this.setState({appointment})
    
    this.calculateTotal(line_items, (values) => {
      this.setState({
        line_items: values.line_items,
        total: values.total || 0,
        total_tax: values.total_tax || 0,
        total_amount_due: values.total_amount_due || 0
      });
    });
  }

  accountBalance = (student) => {
    const std = student ?? this.state.student
    if (std && this.state.appointment && this.state.appointment.demo){
      return "";
    } else if (!std) {
      return "0.00";
    } else {
      return (std.balance * 1.0 / 100).toFixed(2);
    }
  }

  setStudent = (student) => {
    if (student) {
      let appointment;
      const { default_user, default_appointment } = this.state;

      if ((student && student.id) == (default_user && default_user.id)) {
        appointment = default_appointment;
      } else {
        appointment = null;
      }
      
      const accountBalance = this.accountBalance(student);
      const paymentMethod =  (accountBalance === "0.00" || accountBalance === "") ? DEFAULT_PAYMENT_OPTION : this.getPaymentMethod(BALANCE);

      this.setState({payment_method: paymentMethod, student, appointment }, () => {
          this.loadAppointments(); 
      });

    } else {
      this.setState({ student, appointment: null, appointments: [], payment_method: {} });
    }
  }

  guestPayer = (payer_name) => ({
    label: payer_name,
    balance: 0,
    id: null,
    guest: true
  });

  demoGuestPayer = (demo, payer_name) => ({
    label: payer_name,
    balance: 0,
    id: null,
    guest: true,
    demo: typeof (demo) != "undefined" ? demo : false
  });

  createGuestPayer = (payer_name) => {
    const student = this.guestPayer(payer_name);

    this.setState({ student, appointments: [], payment_method: DEFAULT_GUEST_PAYMENT_OPTION });
  }

  isGuestNameValid = (inputValue, selectValue, selectOptions) => {
    return !(
      inputValue.trim().length === 0 ||
      selectOptions.find(option => option.first_name + " " + option.last_name === inputValue)
    );
  };

  setDate = (date) => { console.log(date); this.setState({ date }); }

  setPaymentMethod = (option) => { this.setState({ payment_method: option }); }

  onLineItemsTableChange = (values) => {
    if(
      isMaintenanceInvoice({}, values.line_items)) {
       this.setState({
         ...(values ?? {}),
         hobb_tach_warning_accepted: false,
         payment_method: DEFAULT_MAINTENANCE_PAYMENT_OPTION
      });
    } else {
      this.setState({ ...(values ?? {}), hobb_tach_warning_accepted: false });
    }
  }

  payload = () => {
    const {
      appointment, student, sales_tax, total, total_tax, total_amount_due, date,
      payment_method, action, is_visible, send_receipt_email, appt_status
    } = this.state;
    const is_edit = action == 'edit';

    const line_items = is_edit ? this.state.line_items : this.state.line_items.map(i => {
      delete Object.assign({}, i).id;
      return i;
    });

    return {
      ignore_last_time: is_edit,
      line_items,
      user_id: isEmpty(this.props.course) ? this.getUserId(student, appointment) : this.props.current_user_id,
      payer_name: student && student.guest ? student.label : '',
      date: date.toISOString(),
      tax_rate: sales_tax,
      notes: this.state.notes,
      payer_email: this.state.payer_email,
      total,
      total_tax,
      total_amount_due,
      payment_option: payment_method.value,
      is_visible: is_visible,
      appointment_id: appointment && appointment.id,
      course_id: isEmpty(this.props.course) ? null : this.props.course.id,
      send_receipt_email,
      appt_status
    }
  }

  getUserId = (student, appointment) => {
    if(student?.id) {
      return student.id;
    }

    if(appointment?.mechanic_user || appointment?.mechanic_user_id) {
      return appointment.mechanic_user.id || appointment.mechanic_user_id;
    }
  }

  showBalanceWarning = () => {
    const { total_amount_due, student, payment_method, balance_warning_accepted } = this.state;

    const open = !balance_warning_accepted &&
      payment_method.value == BALANCE &&
      student &&
      total_amount_due > student.balance;

    if (open) this.setState({ balance_warning_open: true });

    return open;
  }

  showHobbTachWarning = (warningMsg) => {
    if ( warningMsg != "" ) {
      this.setState({hobb_tach_warning_open: true, warningMsg: warningMsg});
    }
  }

  saveInvoice = ({ pay_off }) => {
    if (this.state.saving) return;

    this.setState({ saving: true });

    const payload = this.payload();
    const http_method = this.state.action == 'edit' ? 'put' : 'post';

    http[http_method]({
      url: `/api/invoices/${this.state.id}`,
      body: { pay_off: pay_off, invoice: payload },
      headers: authHeaders()
    }).then(response => {
      response.json().then(({ data }) => {
        if (pay_off && data.session_id && data.connect_account && data.pub_key) {

          if (http_method == 'post') {
            localStorage.setItem('invoice_id', data.id)
          }

          this.stripeCheckout(data.session_id, data.connect_account, data.pub_key)
          return;
        }

        window.location = `/billing/invoices/${data.id}`;
      });
    }).catch(response => {
      response.json().then((error_body) => {
        console.warn(error_body);
        const { id = this.state.id, stripe_error = '', error = '', errors = {} } = error_body;
        const action = id ? 'edit' : 'create';
        
        const line_items = this.state.line_items || []
        const isInstructorOnly = line_items.length == 1 && line_items[0].type === "instructor"

        this.setState({
          saving: false, id, action,
          stripe_error, error, errors,
          error_alert_total_open: !isInstructorOnly && this.state.total <= 0
        });
      });
    });
  }

  calculateTotal = (line_items, callback) => {
    if (calculateRequest.hasOwnProperty('cancel')) {
      calculateRequest.cancel();
    }

    const { student, appointment, action } = this.state;
    
    const payload = {
      ignore_last_time: action == 'edit',
      line_items,
      user_id: this.getUserId(student, appointment),
      appointment_id: appointment && appointment.id
    }

    if (!this.state.saving) this.setState({ saving: true });


    calculateRequest = debounce(payloadParams => {
      http.post({
        url: '/api/invoices/calculate?' + addSchoolIdParam(),
        body: { invoice: payloadParams },
        headers: authHeaders()
      }).then(response => {
        this.setState({ saving: false });
        response.json().then(callback);
      }).catch(response => {
        this.setState({ saving: false });
        response.json().then((err) => {
          console.warn(err);
        });
      });
    }, 500);

    calculateRequest(payload);
  }

  async stripeCheckout(sessionId, accountId, pub_key) {
    const stripe = await loadStripe(pub_key, {stripeAccount: accountId});

    stripe.redirectToCheckout({
        sessionId:sessionId
      })
      .then(({ error }) => {
        console.log(error);
      });
  }

  confirmCloseAlert = () => {
    this.setState({confirm_alert_open: true});
  }

  submitForm = ({ pay_off }) => {
    const line_items = this.state.line_items || []
    const isInstructorOnly = line_items.length == 1 && line_items[0].type === "instructor"
    
    if (this.state.saving) return;

    // We don't need to check total amount if invoice is for maintenance
    if(!isMaintenanceInvoice(this.state.appointment, line_items)) {
      if (!isInstructorOnly && this.state.total < 0) {
        this.setState({error_alert_total_open: true});
        return;
      }
      if (!isInstructorOnly && this.state.total_amount_due < 0) {
        this.setState({error_alert_total_due_open: true});
        return;
      }
      if (!isInstructorOnly &&this.state.total_tax < 0) {
        this.setState({error_alert_total_tax_open: true});
        return;
      }
    }

    if ( this.state.line_items.length > 0) {
      for (let increment in this.state.line_items) {
        if (this.state.line_items[increment].type == "aircraft") {

          const hobbs_end = this.state.line_items[increment].hobbs_end
          const tach_end = this.state.line_items[increment].tach_end
  
          // make sure hobbs end and tach ends must be set
          if(!(hobbs_end && tach_end)) {
            return this.setState({ending_hobbs_tach_error: true});
          }

          if(typeof(this.state.line_items[increment].errors) != "undefined" && !this.state.demo) {
            return;
          } else{
            if (!this.state.hobb_tach_warning_accepted &&
                ( (this.state.line_items[increment].hobbs_end - this.state.line_items[increment].hobbs_start) > 120 ||
                ( this.state.line_items[increment].tach_end - this.state.line_items[increment].tach_start) > 120 ) ) {

              var warningMsg = ""

              if ( (this.state.line_items[increment].hobbs_end - this.state.line_items[increment].hobbs_start) > 120 &&
                (this.state.line_items[increment].tach_end - this.state.line_items[increment].tach_start) > 120 ) {
                warningMsg = "Your Hobbs and Tach end time is more than 12 hours greater than your start time. Are you sure that this is correct?"
              }
              else if ((this.state.line_items[increment].hobbs_end - this.state.line_items[increment].hobbs_start) > 120) {
                warningMsg = "Your Hobbs end time is more than 12 hours greater than your start time. Are you sure that this is correct?"
              }
              else if ((this.state.line_items[increment].tach_end - this.state.line_items[increment].tach_start) > 120) {
                warningMsg = "Your Tach end time is more than 12 hours greater than your start time. Are you sure that this is correct?"
              }

              this.showHobbTachWarning(warningMsg)
                return;
            }

            if (pay_off && (typeof(this.state.appointment) == "undefined" || (this.state.appointment) && Date.now() < Date.parse(moment.utc(this.state.appointment.start_at).add(+(moment().utcOffset()), 'm').format().split("Z")[0]))) {
              
              var appointmentMsg = "Invoice associated with aircraft cannot be paid before the starting time of appointment."
              if (containsSimulator(this.state.line_items)) {
                appointmentMsg = "Invoice associated with simulator cannot be paid before the starting time of appointment."
              }
              
              this.setState({error_date_alert_open: true, appointmentMsg: appointmentMsg});
              return;
            }
          }
        }
      }
    }

    if (pay_off && this.showBalanceWarning()) return;

    if (this.formRef.checkValidity()) {
      this.saveInvoice({ pay_off });
    }
  }

  globalError = () => {
    if ('error' in this.state) return this.state.error.message
  }

  saveAndPayButton = () => {
    const { payment_method: { value }, saving } = this.state;
    const inputValue = "Pay Now";//[CASH, CHECK, VENMO].includes(value) ? MARK_AS_PAID : PAY
    return (
      <input className="btn btn-success invoice-form__pay-btn"
        type="submit"
        disabled={saving}
        value={inputValue}
        onClick={() => { this.submitForm({ pay_off: true }) }} />
    );
  }

  header = () => {
    const { id } = this.state;
    const header = id ? `Edit Invoice #${id}` : 'New Invoice';

    return header;
  }

  closeBalanceWarning = () => {
    this.setState({ balance_warning_open: false });
  }

  closeHobbTachWarning = () => {
    this.setState({ hobb_tach_warning_open: false });
  }

  acceptHobbTachWarning = () => {
    this.setState({ hobb_tach_warning_accepted: true});
    this.setState({ hobb_tach_warning_open: false });
  }

  closeTotalErrorAlert = () => {
    this.setState({ error_alert_total_open: false });
  }

  closeEndingHobbsTachAlert = () => {
    this.setState({ ending_hobbs_tach_error: false });
  }

  closeTotalDueErrorAlert = () => {
    this.setState({ error_alert_open: false });
  }

  closeTotalTaxErrorAlert = () => {
    this.setState({ error_alert_total_due_open: false });
  }

  closeErrorDateAlert = () => {
    this.setState({ error_date_alert_open: false });
  }

  confirmAlert = () => {
    this.setState({ confirm_alert_open: false });
    const { id } = this.state;
    const location = id ? `/billing/invoices/${id}` : `/billing/invoices`;
    window.location = location;
  }

  rejectAlert = () => {
    this.setState({ confirm_alert_open: false });
  }

  acceptBalanceWarning = () => {
    this.setState({ balance_warning_open: false, balance_warning_accepted: true });
    const {student, user_roles} = this.state;
    const shouldAddcc = (student && !student.has_cc)
    
    if (shouldAddcc) {
      var path = `/admin/users/${student.id}/edit`

      if(user_roles && user_roles.includes("instructor")) {
        path = `/instructor/students/${student.id}/edit`

      } else if ( user_roles && user_roles.includes('student')) {
        path = `/student/profile/edit`
      }

      window.location = path

    } else {
      this.saveInvoice({ pay_off: true });
    }
  }

  userErrors = (errorText) => {
    if (errorText == "One of these fields must be present: [:user_id, :payer_name]") {
      return "can't be blank";
    } else {
      return errorText;
    }
  }

  studentSelect = (is_admin_invoice) => {
    const { errors, student, students } = this.state;
   
    return (
      <div className={classnames('invoice-select-wrapper', errors.user_id ? 'with-error' : '')}>
        <CreatableSelect placeholder="Search or Type to create a new user"
          isClearable
          isValidNewOption={this.isGuestNameValid}
          onCreateOption={this.createGuestPayer}
          classNamePrefix="react-select"
          options={students}
          onChange={this.setStudent}
          getOptionLabel={(o) => (o.label || o.first_name + ' ' + o.last_name)}
          getOptionValue={(o) => o.id}
          isDisabled={is_admin_invoice}
          value={student} />
      </div>
    )
  }

  checkBoxClicked = (e) => {
    console.log(e.target.value)
    //console.log('tesetset')
    //const appt_status = this.state.appt_status;
    
    this.setState({
      appt_status: e.target.value
    })
  }

  render() {
    const { custom_line_items, staff_member } = this.props;
    const {appt_status, aircrafts, simulators, appointment, appointment_loading, appointments,
      instructors, rooms, date, errors, id, invoice_loading, line_items, payment_method, sales_tax,
      saving, stripe_error, student, total, total_amount_due, total_tax, is_admin_invoice,
    } = this.state;
    // check if line_items contains maintenance item
    const maintenanceInvoice = isMaintenanceInvoice(appointment, line_items)
    const mechanic = appointment?.mechanic_user;

    const demo = !this.state.demo && containsDemoFlight(line_items)
    const isCheckRide = appointment && appointment.type == "check_ride" 
    // const isChecked = appt_status == "pass" 

    // In case of guest user don't have credit card payment option
    // so they have to pay in cash, venmo, or check

    // if student balance is zero, we have to remove balance payment method
    // because we do different calculations based on payment method
    const accountBalance = this.accountBalance();
    let paymentOptions =  (accountBalance === "0.00" || accountBalance === "") ? PAYMENT_OPTIONS.filter(option => option.value !== BALANCE) : PAYMENT_OPTIONS;
    
    if(maintenanceInvoice) {
      paymentOptions = MAINTENANCE_PAYMENT_OPTIONS;
    } else if(demo) {
      paymentOptions = DEMO_PAYMENT_OPTIONS;
    } else if(student?.guest) {
      paymentOptions = GUEST_PAYMENT_OPTIONS;
    }

    return (
      <div className="card">
        <div className="card-header text-left">
          <h3 className="card-title">{this.header()}</h3>
        </div>

        <div className="card-body">
          <div className="invoice-form">
            <div className="form">
              <form ref={this.setFormRef}>
               {isEmpty(this.props.course) && ( <>
                  {
                    mechanic ? (
                      <div className="form-group">
                        <label>
                          Person Name
                        </label>
                        <div>{mechanic.first_name + ' ' + mechanic.last_name}</div>
                      </div>
                    ) : (
                      <div className="form-group">
                        <label>
                          Person Name
                          <Error text={this.userErrors(errors.user_id)} />
                        </label>
                        { staff_member && this.studentSelect(is_admin_invoice) }
                        { !staff_member && <div>{student.first_name + ' ' + student.last_name}</div> }
                      </div>
                    )
                  }
                  </>
               )}

                {
                !isEmpty(this.props.course) && <div className="form-group">
                        <label>
                            Course Title
                        </label>
                        <p>{this.props.course.coursename}</p>
                    </div> 
                }

                {
                  isEmpty(this.props.course) && <div className="form-group">
                    <label>
                      Appointment
                      <Error text={errors.appointment_id} />
                    </label>
                    <div className={classnames('invoice-select-wrapper', errors.appointment_id ? 'with-error' : '')}>
                      <Select placeholder="Appointment"
                        isClearable
                        classNamePrefix="react-select"
                        options={appointments}
                        onChange={this.setAppointment}
                        isLoading={appointment_loading}
                        getOptionLabel={this.appointmentLabel}
                        getOptionValue={(o) => o.id}
                        isDisabled={!student || student.guest || is_admin_invoice}
                        value={appointment} />
                    </div>
                  </div>
                }

                <div className="form-group">
                  <label>Acct Balance</label>
                  <div>${this.accountBalance()}</div>
                </div>

                <div className="row">
                {id && <div className="form-group col-md-2">
                  <label>Invoice #</label>
                  <div>{id}</div>
                </div>}
                
                {isCheckRide && this.enableCheckRideStatus() && <div className="form-group col-md-10">
                    <div className="row">
                      <div className="form-check form-check-inline">
                        <div className="form-check">
                          <label className="form-check-label">
                            <input className="form-check-input" type="checkbox" name="appt_status" checked = {this.state.appt_status === "pass"} value="pass" onChange={this.checkBoxClicked}/>
                            <span className="form-check-sign"></span>
                            Pass
                          </label>
                        </div>
                      </div>
                      <div className="form-check form-check-inline">
                        <div className="form-check">
                          <label className="form-check-label">
                            <input className="form-check-input" name="appt_status" type="checkbox" checked = {this.state.appt_status === "fail"} value="fail" onChange={this.checkBoxClicked} />
                            <span className="form-check-sign" ></span>
                            Fail
                          </label>
                        </div>
                      </div>                      
                      {this.state.appt_status === 'fail' && 
                        <div className="form-check form-check-inline">
                          <div className="form-check">
                            <label className="form-check-label">
                              Please enter Fail reason in invoice notes.
                            </label>
                          </div>
                        </div>
                      }
                    </div>
                  </div>}
                </div>

                <div className="form-group">
                  <label>
                    Payment Date
                    <Error text={errors.date} />
                  </label>
                  <div>
                    <DatePicker className="form-control invoice-input"
                      selected={date}
                      required={true}
                      onChange={this.setDate} />
                  </div>
                </div>

                <div className="form-group">
                  {!invoice_loading &&
                    <LineItemsTable aircrafts={aircrafts}
                      simulators={simulators}
                      appointment={appointment}
                      student={student}
                      creator={this.props.creator}
                      staff_member={staff_member}
                      custom_line_items={custom_line_items}
                      errors={errors}
                      instructors={instructors}
                      rooms={rooms}
                      line_items={line_items}
                      onChange={this.onLineItemsTableChange}
                      calculateTotal={this.calculateTotal}
                      sales_tax={sales_tax}
                      total={total}
                      total_amount_due={total_amount_due}
                      total_tax={total_tax}
                      current_user_id={this.state.current_user_id}
                      user_roles = {this.state.user_roles}
                      is_admin_invoice = {is_admin_invoice}
                      course={this.props.course} 
                      is_maintenance_invoice = {maintenanceInvoice}
                      />
                  }
              </div>

                <div className="form-group">
                {
                    (demo || student?.guest) && (
                      <>
                        <label>
                          Add Email to Send this Invoice
                        </label>
                        <div className="invoice-select-wrapper">
                          <input className="form-control"
                            type="email"
                            placeholder="Enter demo or guest user email"
                            value={this.state.payer_email || ''}
                            onChange={(event) =>  this.setState({
                              payer_email: event.target.value
                            })
                          } 
                          />
                        </div>
                      </>
                    )
                  }
                  <label>
                    Invoice Notes
                  </label>
                  <div className="invoice-select-wrapper">
                    <textarea 
                      className="form-control"
                      aria-label="With textarea"
                      value={this.state.notes || ''}
                      onChange={(event) =>  this.setState({
                          notes: event.target.value
                        })
                      }
                    />
                  </div>

                  <label>
                    Payment Method
                    <Error text={errors.payment_option} />
                  </label>
                  <div className="invoice-select-wrapper">
                    <Select placeholder="Payment method"
                      value={payment_method}
                      classNamePrefix="react-select"
                      options={paymentOptions}
                      onChange={this.setPaymentMethod}
                      required={true} />
                  </div>
                  <div><Error text={stripe_error} /></div>

                  <div className="checkbox-radios">
                      <div className="form-check">
                        <label className="form-check-label">
                          <input 
                            type="checkbox" 
                            name="send_invoice_receipt" 
                            checked={this.state.send_receipt_email}
                            onChange={(event) => this.setState({
                                send_receipt_email: !this.state.send_receipt_email
                              })
                            }
                          />
                          <span className="form-check-sign"></span>
                          Send invoice receipt email
                        </label>
                      </div>
                  </div>

                </div>

                <div id="save_and_pay" className="form-group invoice-save-buttons">
                  { isEmpty(this.props.course) && !is_admin_invoice &&
                    <input className="btn btn-primary"
                      type="submit"
                      value="Save for later"
                      disabled={saving}
                      onClick={() => { this.submitForm({ pay_off: false }) }} />
                  }
                  <input className="btn btn-default"
                    type="button"
                    value="Cancel"
                    onClick={() => { this.confirmCloseAlert() }} />

                  {this.saveAndPayButton()}

                </div>

                <div className="form-group">
                  <Error text={this.globalError()} />
                </div>
              </form>
            </div>
          </div>
        </div>

        <LowBalanceAlert open={this.state.balance_warning_open}
          onClose={this.closeBalanceWarning}
          onAccept={this.acceptBalanceWarning}
          balance={student ? student.balance : 0}
          student={student}
          total={total_amount_due}
        />

        <ConfirmHobbTachAlert open={this.state.hobb_tach_warning_open}
          onReject={this.closeHobbTachWarning}
          onAccept={this.acceptHobbTachWarning}
          text={this.state.warningMsg}
        />

      <ErrorAlert open={this.state.error_alert_total_open}
          onAccept={this.closeTotalErrorAlert}
          text="Invoices cannot be saved with a total amount below or equal to zero."
      />

      <ErrorAlert open={this.state.ending_hobbs_tach_error}
          onAccept={this.closeEndingHobbsTachAlert}
          text="Ending hobbs and tach hours must be filled correctly"
      />

      <ErrorAlert open={this.state.error_alert_total_due_open}
          onAccept={this.closeTotalDueErrorAlert}
          text="Invoices cannot be saved with a total amount below or equal to zero."
      />

      <ErrorAlert open={this.state.error_alert_total_tax_open}
          onAccept={this.closeTotalTaxErrorAlert}
          text="Invoices cannot be saved with a total amount below or equal to zero."
      />


      <ErrorAlert open={this.state.error_date_alert_open}
          onAccept={this.closeErrorDateAlert}
          text={this.state.appointmentMsg}
      />


      <ConfirmAlert open={this.state.confirm_alert_open}
          onAccept={this.confirmAlert}
          onReject={this.rejectAlert}
          text="Changes will not be saved. Are you sure that you want to cancel! "
      />

      </div>
    );
  }

  enableCheckRideStatus() {
    if ( this.props.user_roles.includes('admin') || this.props.user_roles.includes('instructor') ) {
      return true;
    }
    return false;
  }
}

export default Form;
