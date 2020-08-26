import shortid from 'shortid';

export const FLIGHT_HOURS = "Flight Hours";
export const INSTRUCTOR_HOURS = "Instructor Hours";

export const DEFAULT_TYPE = "other";
export const TYPES = {
  [FLIGHT_HOURS]: "aircraft",
  [INSTRUCTOR_HOURS]: "instructor"
}

export const DESCRIPTION_OPTS = [
  {label: FLIGHT_HOURS, value: FLIGHT_HOURS, taxable: true, deductible: false},
  {label: INSTRUCTOR_HOURS, value: INSTRUCTOR_HOURS, taxable: false, deductible: false}
];

export const DEFAULT_RATE = 0;

export const NUMBER_INPUT_OPTS = {
  allowNegative: false,
  decimalScale: 2,
  fixedDecimalScale: 2,
  required: true,
  placeholder: "0.00",
  thousandSeparator: true,
  className: "form-control inherit-font-size"
};
export const DESCRIPTION_SELECT_OPTS = {
  classNamePrefix: "react-select",
  isClearable: false,
  isRtl: false,
  isSearchable: false,
  name: "description",
  required: true
};

export const populateHobbsTach = (aircraft) => {
  const hobbs_start = aircraft && aircraft.last_hobbs_time || 0;
  const hobbs_end = null;
  const tach_start = aircraft && aircraft.last_tach_time || 0;
  const tach_end = null;

  return { hobbs_start, hobbs_end, tach_start, tach_end };
}

export class LineItemRecord {
  constructor(params = {}) {
    this.id = shortid.generate();
    this.description = params.description;
    this.rate = params.rate || DEFAULT_RATE;
    this.quantity = params.quantity || 1;
    this.amount = this.rate * this.quantity;
    this.type = TYPES[this.description] || DEFAULT_TYPE;
    this.instructor_user = params.instructor_user;
    this.instructor_user_id = params.instructor_user && params.instructor_user.id;
    this.aircraft = params.aircraft;
    this.aircraft_id = params.aircraft && params.aircraft.id;
    this.taxable = params.taxable;
    this.deductible = params.deductible;

    if (this.type == "aircraft") {
      const { hobbs_start, hobbs_end, tach_start, tach_end } = populateHobbsTach(this.aircraft);
      this.hobbs_start = hobbs_start;
      this.hobbs_end = this.hobbs_end || hobbs_end;
      this.tach_start = tach_start;
      this.tach_end = this.tach_end || tach_end;
      this.quantity = 0;
    }
  }
};

const HOUR_IN_MILLIS = 3600000;

export const itemsFromAppointment = (appointment, line_items) => {
  line_items = line_items || []
  
  if (appointment) {
    const duration = (new Date(appointment.end_at) - new Date(appointment.start_at)) / HOUR_IN_MILLIS;
    const items = [];
    if (appointment.instructor_user) {
      var item = findItem(line_items, "instructor")
      
      if (!item) {
        item = instructorItem(appointment.instructor_user, duration);
      }

      items.push(item)
    }

    if (appointment.aircraft) {
      var item = findItem(line_items, "aircraft")
      if (!item) {
        item = fromAircraft(appointment.aircraft)
      }       
      
      item.hobbs_start = appointment.start_hobbs_time || item.hobbs_start;
      item.hobbs_end = appointment.end_hobbs_time || item.hobbs_end;

      item.tach_start = appointment.start_tach_time || item.tach_start;
      item.tach_end = appointment.end_tach_time || item.tach_end;
      item.demo = appointment.demo
      
      if (appointment.demo) {
        item.enable_rate = true
      }

      if (appointment.end_hobbs_time > 0) {
        item.disable_flight_hours = true
        item.enable_rate = false

      } else {
        item.disable_flight_hours = false
      }

      items.push(item); 
    }
    const keys = items.map(function(item){return item.id})
   
    const others = line_items.filter(function(item){return !(keys.includes(item["id"]))})

    return items.concat(others);
  } else {
    return [
      new LineItemRecord({ description: '' })
    ]
  }
}

const instructorItem = (instructor_user, duration) => {
  return new LineItemRecord({
    quantity: duration,
    rate: instructor_user.billing_rate,
    description: INSTRUCTOR_HOURS,
    instructor_user: instructor_user,
    taxable: false,
    deductible: false
  });
}

const fromAircraft = (aircraft, duration) => {
  return new LineItemRecord({
    quantity: duration,
    rate: aircraft.rate_per_hour,
    description: FLIGHT_HOURS,
    aircraft,
    taxable: true,
    deductible: false
  });
}

export const itemsFromInvoice = (invoice) => {
  if (invoice.appointment_id || !invoice.aircraft_info || !invoice.line_items) {return invoice}

  let index = -1
  const aircraft = 
    invoice.line_items.find(function(item, curr_index, _arr){
      index = curr_index
      return item.type == "aircraft"
    })

  if (aircraft && aircraft.hobbs_end > 0) {aircraft.disable_flight_hours = true}
  
  if (index < invoice.line_items.length) {
    invoice.line_items[index] = aircraft
  }

  return invoice
}

export const isInstructorHoursEditable = (line_item, user_roles) => {
  return line_item.type === "instructor" && user_roles.includes("instructor")
  // return line_item.type === "instructor" && current_user_id == line_item.instructor_user_id && current_user_id !== undefined
}


function findItem(line_items, type){
  const existing_items = line_items || []
  return existing_items.find(function(item) {return item.type == type})
}