export const authHeaders = () => ({ 'Authorization': window.fsm_token });
export const addSchoolIdParam = (prefix = '', postfix = '') => {
  let span = document.getElementById('current-school')

  if (span) {
    return prefix + "school_id=" + span.dataset.schoolId + postfix
  } else { return '' }
}
