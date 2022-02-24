import EctoEnum

defenum(InvoiceStatusEnum, pending: 0, paid: 1)

defenum(
  InvoicePaymentOptionEnum,
  balance: 0,
  cc: 1,
  cash: 2,
  cheque: 3,
  venmo: 4,
  fund: 5,
  maintenance: 6
)

defenum(
  InvoiceLineItemTypeEnum,
  other: 0,
  aircraft: 1,
  instructor: 2,
  discount: 3,
  room: 4,
  course: 5,
  fund: 6,
  course_invoice: 7,
  maintenance: 8,
  parts: 9
)

defenum(AppointmentStatusEnum, pending: 0, paid: 1)

defenum(
  SchoolOnboardingCurrentStepEnum,
  school: 0,
  contact: 1,
  profile: 2,
  resources: 3,
  payment: 4,
  billing: 5
)

defenum(
  SquawkSeverityEnum,
  ground: 0,
  fix_soon: 1,
  no_fix_required: 2
)

defenum(
  AlertPriorityEnum,
  top: 0,
  high: 1,
  medium: 2,
  low: 3
)

defenum(
  AlertCodeEnum,
  squawk_issue: "SQK-001"
)
