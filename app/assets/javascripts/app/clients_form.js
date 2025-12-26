import { formatDoc, formatPhone, formatCEP, onlyDigits } from "../utils/formatters";
import { isValidCPF, isValidCNPJ } from "../utils/validators";

document.addEventListener("DOMContentLoaded", function () {
  // Documento (CPF/CNPJ)
  document.querySelectorAll('input[data-mask="document"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatDoc(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });

    // Validação ao sair do campo
    input.addEventListener("blur", function () {
      const digits = onlyDigits(input.value);
      let valid = false;
      if (digits.length === 11) valid = isValidCPF(digits);
      else if (digits.length === 14) valid = isValidCNPJ(digits);

      let errorEl = input.nextElementSibling;
      if (!errorEl || !errorEl.classList.contains("invalid-feedback")) {
        errorEl = document.createElement("div");
        errorEl.className = "invalid-feedback d-block";
        input.parentNode.insertBefore(errorEl, input.nextSibling);
      }

      if (!valid) {
        errorEl.textContent = "Documento inválido. Informe um CPF ou CNPJ válido.";
        input.classList.add("is-invalid");
      } else {
        errorEl.textContent = "";
        input.classList.remove("is-invalid");
      }
    });
  });

  // Bloquear envio do formulário se documento inválido
  const form = document.querySelector("form");
  if (form) {
    form.addEventListener("submit", function (e) {
      const docInput = form.querySelector('input[data-mask="document"]');
      if (docInput) {
        const digits = onlyDigits(docInput.value);
        let valid = false;
        if (digits.length === 11) valid = isValidCPF(digits);
        else if (digits.length === 14) valid = isValidCNPJ(digits);

        if (!valid) {
          e.preventDefault();
          docInput.classList.add("is-invalid");
          let errorEl = docInput.nextElementSibling;
          if (!errorEl || !errorEl.classList.contains("invalid-feedback")) {
            errorEl = document.createElement("div");
            errorEl.className = "invalid-feedback d-block";
            docInput.parentNode.insertBefore(errorEl, docInput.nextSibling);
          }
          errorEl.textContent = "Documento inválido. Informe um CPF ou CNPJ válido.";
          docInput.focus();
        }
      }
    });
  }

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