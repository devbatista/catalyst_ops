import { formatPhone } from "../utils/formatters";

document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll('input[data-mask="phone"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatPhone(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });
});