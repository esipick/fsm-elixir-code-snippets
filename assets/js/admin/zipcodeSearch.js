function zipCodeChanged() {
  var x = document.getElementById("data_zipcode");
  const zip_code = x.value

  if (!zip_code || zip_code.trim() === "") {return}
  
  const AUTH_HEADERS = { "authorization": window.fsm_token };

  $.get({ url: "/api/zip_code/" + zip_code, headers: AUTH_HEADERS }).then(function(info){
    const city = document.getElementById("data_city")
    const state = document.getElementById("data_state")
    
    city.value = info.city
    state.value = info.state
  })
}