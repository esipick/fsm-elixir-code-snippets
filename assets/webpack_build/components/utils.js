export const authHeaders = () => ({ 'Authorization': window.fsm_token });
export const addSchoolIdParam = (prefix = '', postfix = '') => {
  let span = document.getElementById('current-school')

  if (span) {
    return prefix + "school_id=" + span.dataset.schoolId + postfix
  } else { return '' }
}

export const getAccountBalance = (student) => {
  if (!student) {
    return 0;
  }

  const rawBalance =(student.balance * 1.0 / 100).toFixed(2);
  return parseFloat(rawBalance);
}

/**
 * 
 * @param non-null and non-undefined object 
 * @returns true | false
 */
export const isEmpty = (obj) => {
  return Object.keys(obj || {}).length === 0
}

/**
 * 
 * @param {function} f - any function 
 * @param {number} wait - time in seconds
 * @returns function
 */

export const debounce = (f, wait) => {
	let timeout;

	return (...args) => {
		const fncall = () => f.apply(this, args);

		clearTimeout(timeout);
		timeout = setTimeout(fncall, wait);
	}
};