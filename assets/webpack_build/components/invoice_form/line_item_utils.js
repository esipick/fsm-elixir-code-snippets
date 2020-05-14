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

export const DEFAULT_RATE = 100;

export class LineItemRecord {
  constructor(params = {}) {
    this.id = shortid.generate();
    this.description = params.description || DESCRIPTION_OPTS[0].value;
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
      new LineItemRecord({ description: DESCRIPTION_OPTS[0].value, taxable: true, deductible: false })
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
