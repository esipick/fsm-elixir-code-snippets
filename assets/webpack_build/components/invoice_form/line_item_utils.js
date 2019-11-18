import shortid from 'shortid';

export const FLIGHT_HOURS = "Flight Hours";
export const INSTRUCTOR_HOURS = "Instructor Hours";

export const DEFAULT_TYPE = "other";
export const TYPES = {
  [FLIGHT_HOURS]: "aircraft",
  [INSTRUCTOR_HOURS]: "instructor"
}

export const DESCRIPTION_OPTS = [
  FLIGHT_HOURS,
  INSTRUCTOR_HOURS,
  "Fuel Charge",
  "Fuel Reimbursement",
  "Equipment Rental"
].map(o => ({ label: o, value: o }));

export class LineItemRecord {
  constructor(params = {}) {
    this.id = shortid.generate();
    this.description = params.description || DESCRIPTION_OPTS[0].value;
    this.rate = params.rate || 100;
    this.quantity = params.quantity || 1;
    this.amount = this.rate * this.quantity;
    this.type = TYPES[this.description] || DEFAULT_TYPE;
    this.instructor_user = params.instructor_user;
    this.aircraft = params.aircraft;
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
    return [new LineItemRecord()]
  }
}

const instructorItem = (instructor_user, duration) => {
  return new LineItemRecord({
    quantity: duration,
    rate: instructor_user.billing_rate,
    description: INSTRUCTOR_HOURS,
    instructor_user: instructor_user
  });
}

const fromAircraft = (aircraft, duration) => {
  return new LineItemRecord({
    quantity: duration,
    rate: aircraft.rate_per_hour,
    description: FLIGHT_HOURS,
    aircraft
  });
}
