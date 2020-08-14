export const BALANCE = 'balance';
export const CREDIT_CARD = 'cc';
export const CASH = 'cash';
export const CHEQUE = 'cheque';
export const VENMO = 'venmo';

export const MARK_AS_PAID = 'Save and Mark as paid';
export const PAY = 'Save and Pay';

export const GUEST_PAYMENT_OPTIONS = [
  { value: CASH, label: 'Cash' },
  { value: CHEQUE, label: 'Cheque' },
  { value: VENMO, label: 'Venmo' }
];
export const DEFAULT_PAYMENT_OPTION = { value: CREDIT_CARD, label: 'Credit Card' };
export const DEFAULT_DEMO_PAYMENT_OPTION = { value: BALANCE, label: 'Balance' };
export const PAYMENT_OPTIONS = [
  DEFAULT_PAYMENT_OPTION,
  { value: BALANCE, label: 'Balance' },
  ...GUEST_PAYMENT_OPTIONS
];
export const DEMO_PAYMENT_OPTIONS = [
  DEFAULT_PAYMENT_OPTION,
  ...GUEST_PAYMENT_OPTIONS
];

export const modalStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)'
  }
};
