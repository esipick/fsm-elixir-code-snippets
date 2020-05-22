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
    this.quantity = params.quantity || 0;
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
      this.hobbs_end = hobbs_end;
      this.tach_start = tach_start;
      this.tach_end = tach_end;
      this.quantity = 0;
    }
  }
};

const HOUR_IN_MILLIS = 3600000;

export const itemsFromAppointment = (appointment) => {
  if (appointment) {
    const duration = (new Date(appointment.end_at) - new Date(appointment.start_at)) / HOUR_IN_MILLIS;
    const items = [];

    if (appointment.instructor_user) {
      items.push(instructorItem(appointment.instructor_user, duration));
    }

    if (appointment.aircraft) { items.push(fromAircraft(appointment.aircraft)); }

    return items;
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
