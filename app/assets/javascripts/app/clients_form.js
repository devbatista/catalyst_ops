import { formatDoc, formatPhone, formatCEP, onlyDigits } from "../utils/formatters";

document.addEventListener("DOMContentLoaded", function () {
  // Documento (CPF/CNPJ)
  document.querySelectorAll('input[data-mask="document"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatDoc(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });

  // Telefone
  document.querySelectorAll('input[data-mask="phone"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatPhone(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });

  // CEP
  document.querySelectorAll('input[data-mask="cep"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatCEP(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });
});