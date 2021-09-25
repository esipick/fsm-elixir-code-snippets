export const authHeaders = () => ({ 'Authorization': window.fsm_token });
export const addSchoolIdParam = (prefix = '', postfix = '') => {
  let span = document.getElementById('current-school')

  if (span) {
    return prefix + "school_id=" + span.dataset.schoolId + postfix
  } else { return '' }
}

export const  getAccountBalance = (student) => {
  if (!student) {
    return 0;
  }

  const rawBalance =(student.balance * 1.0 / 100).toFixed(2);
  return parseFloat(rawBalance);
}
