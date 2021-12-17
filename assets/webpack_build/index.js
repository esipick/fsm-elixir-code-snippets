import 'react-phoenix';
import InvoiceForm from './components/invoice_form/Form';
import BulkInvoiceForm from './components/bulk_invoice/Form';
import BulkInvoiceEmailForm from './components/bulk_invoice/bulkInvoiceEmailForm';
import InvoiceCustomLineItem from './components/invoice_custom_line_item/Form';
import Documents from './components/documents/Main';
import CopyLink from './components/copy_link/CopyLink';
import { CourseParticipant } from './components/course-participant';
import 'react-datepicker/dist/react-datepicker.css';
import './styles.css';

window.Components = {
  InvoiceForm,
  BulkInvoiceForm,
  BulkInvoiceEmailForm,
  InvoiceCustomLineItem,
  Documents,
  CopyLink,
  CourseParticipant
};
