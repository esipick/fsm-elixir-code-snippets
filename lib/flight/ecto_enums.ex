import EctoEnum

defenum(InvoiceStatusEnum, pending: 0, paid: 1)

defenum(
  InvoicePaymentOptionEnum,
  balance: 0,
  cc: 1,
  cash: 2,
  cheque: 3,
  venmo: 4
)

defenum(
  InvoiceLineItemTypeEnum,
  other: 0,
  aircraft: 1,
  instructor: 2,
  discount: 3
)

defenum(AppointmentStatusEnum, pending: 0, paid: 1)

defenum(
  SchoolOnboardingCurrentStepEnum,
  school: 0,
  contact: 1,
  profile: 2,
  assets: 3,
  payment: 4,
  billing: 5
)
