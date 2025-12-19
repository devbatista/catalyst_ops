document.addEventListener("DOMContentLoaded", function () {
  var radios = document.querySelectorAll('.payment-methods .pm-input')
  var ccForm = document.getElementById("credit-card-form");

  function toggleCCForm() {
    var selected = document.querySelector('.payment-methods .pm-input:checked')
    if (!selected || !ccForm) return;
    var value = selected.value;
    if (value === "credit_card") {
      ccForm.classList.remove("d-none");
    } else {
      ccForm.classList.add("d-none");
    }
  }

  radios.forEach(function (r) {
    r.addEventListener("change", toggleCCForm);
  });

  // estado inicial
  toggleCCForm();
});