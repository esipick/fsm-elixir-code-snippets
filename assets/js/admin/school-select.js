let schoolSelect = document.getElementById('schoolSelect')
schoolSelect.addEventListener('click', (event) => {
  let schoolId = event.target.dataset.schoolId
  if (schoolId) {
    document.cookie = `school_id=${schoolId};path=/`
    document.location.reload()
  }
})
