import EctoEnum

defenum(InvoiceStatusEnum, pending: 0, paid: 1)

defenum(
  InvoicePaymentOptionEnum,
  balance: 0,
  cc: 1,
  cash: 2,
  check: 3,
  venmo: 4
)

defenum(
  InvoiceLineItemTypeEnum,
  other: 0,
  aircraft: 1,
  instructor: 2,
  discount: 3
)
