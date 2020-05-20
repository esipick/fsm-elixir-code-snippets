$(document).ready(function(){
  var stripe_key = document.getElementById('stripe-key').dataset.key;
  var stripe = Stripe(stripe_key)
  var elements = stripe.elements({
    fonts: [
      {
        cssSrc: 'https://fonts.googleapis.com/css?family=Lato:300,400,700,900',
      }
    ]
  });
  var style = {
    base: {
      fontSize: '12px',
      fontFamily: "'Lato',Helvetica,Arial,sans-serif",
      color: '#2c2c2c',
      fontWeight: 'normal',
      '::placeholder': {
        color: '#BBBCCD',
        fontWeight: '300',
      }
    }
  };
  var form = document.getElementById('stripe-form');
  var card = elements.create('card', {style: style});

  card.mount('#card-element');

  var $submitBtn = $(form).find("input[type='submit']");

  card.addEventListener('change', function(event) {
    var displayError = document.getElementById('card-errors');
    if (event.error) {
      $submitBtn.addClass("disabled");
      displayError.textContent = event.error.message;
    } else {
      $submitBtn.removeClass("disabled");
      displayError.textContent = '';
    }
  });

  var isSubmitting = false;

  var stripeTokenHandler = function(token) {
    var hiddenInput = document.createElement('input');
    hiddenInput.setAttribute('type', 'hidden');
    hiddenInput.setAttribute('name', 'stripe_token');
    hiddenInput.setAttribute('value', token.id);

    form.appendChild(hiddenInput);

    form.submit();
  };

  window.stripeTokenHandler = stripeTokenHandler

  form.addEventListener('submit', function(event) {
    event.preventDefault();

    if (isSubmitting) {
      return;
    }
    isSubmitting = true;

    stripe.createToken(card).then(function(result) {
      if (result.error) {
        isSubmitting = false;
        var errorElement = document.getElementById('card-errors');
        errorElement.textContent = result.error.message;
      } else {
        stripeTokenHandler(result.token);
      }
    });
  });
});
