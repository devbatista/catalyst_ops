import { formatPhone, formatCEP } from "../utils/formatters";

console.error("Company Form JS loaded");

document.addEventListener("DOMContentLoaded", function () {
  // Máscara para telefone
  document.querySelectorAll('input[data-mask="phone"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatPhone(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });

  // Máscara para CEP
  document.querySelectorAll('input[data-mask="cep"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatCEP(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });
});