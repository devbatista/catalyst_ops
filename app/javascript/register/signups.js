import { formatDoc, formatPhone, formatCEP, onlyDigits } from "utils/formatters"
import { isValidCPF, isValidCNPJ } from "utils/validators"

document.addEventListener("DOMContentLoaded", function () {
  // Init BS Stepper
  const el = document.querySelector("#stepper1");
  if (el) {
    el.classList.remove("d-none");
  }

  const hasHeader = el && el.querySelector(".bs-stepper-header, .card-header");
  if (hasHeader && window.Stepper) {
    window.stepper1 = new window.Stepper(el, { linear: false, animation: true });
  }

  // Password show/hide
  function bindToggle(containerSelector) {
    var container = document.querySelector(containerSelector);
    if (!container) return;
    var toggle = container.querySelector("a");
    var input = container.querySelector("input");
    var icon = container.querySelector("i");
    if (toggle && input && icon) {
      toggle.addEventListener("click", function (event) {
        event.preventDefault();
        if (input.type === "text") {
          input.type = "password";
          icon.classList.add("bx-hide");
          icon.classList.remove("bx-show");
        } else {
          input.type = "text";
          icon.classList.remove("bx-hide");
          icon.classList.add("bx-show");
        }
      });
    }
  }
  bindToggle("#show_hide_password");
  bindToggle("#show_hide_password_conf");

  // Helpers
  const isAllEqual = (s) => /^(\d)\1+$/.test(s);

  // Validação de documento (CPF/CNPJ)
  function validateDoc(value) {
    const digits = onlyDigits(value);
    if (digits.length <= 11) return isValidCPF(digits);
    return isValidCNPJ(digits);
  }

  // Campo documento
  const docInput = document.querySelector('[name="signup[company][document]"]');
  if (docInput) {
    const errorId = "company_document_error";
    const ensureErrorEl = () => {
      let el = document.getElementById(errorId);
      if (!el) {
        el = document.createElement("div");
        el.id = errorId;
        el.className = "invalid-feedback d-block";
        docInput.parentElement.appendChild(el);
      }
      return el;
    };

    function showError(msg) {
      const el = ensureErrorEl();
      el.textContent = msg;
      docInput.classList.add("is-invalid");
    }
    function clearError() {
      const el = document.getElementById(errorId);
      if (el) el.textContent = "";
      docInput.classList.remove("is-invalid");
    }

    // Formatar enquanto digita
    docInput.addEventListener("input", function () {
      const prev = docInput.value;
      docInput.value = formatDoc(prev);
      docInput.setSelectionRange(docInput.value.length, docInput.value.length);
    });

    // Validar ao sair do campo
    docInput.addEventListener("blur", function () {
      const ok = validateDoc(docInput.value);
      if (!ok) showError("Documento inválido. Informe um CPF ou CNPJ válido.");
      else clearError();
    });

    // Bloquear avanço se inválido (apenas no passo da empresa)
    document.querySelectorAll('[onclick="stepper1.next()"]').forEach((btn) => {
      btn.addEventListener("click", function (e) {
        const pane = btn.closest("#step-company");
        if (!pane) return;
        const ok = validateDoc(docInput.value);
        if (!ok) {
          e.preventDefault();
          showError("Documento inválido. Informe um CPF ou CNPJ válido.");
          docInput.focus();
        }
      });
    });
  }

  // Campo telefone (Brasil)
  const phoneInput = document.querySelector('[name="signup[company][phone]"]');
  if (phoneInput) {
    phoneInput.addEventListener("input", function () {
      const prev = phoneInput.value;
      phoneInput.value = formatPhone(prev);
      phoneInput.setSelectionRange(phoneInput.value.length, phoneInput.value.length);
    });

    // validação simples: 10 ou 11 dígitos
    phoneInput.addEventListener("blur", function () {
      const digits = onlyDigits(phoneInput.value);
      const valid = digits.length === 10 || digits.length === 11;
      const errorId = "company_phone_error";
      let el = document.getElementById(errorId);
      if (!valid) {
        if (!el) {
          el = document.createElement("div");
          el.id = errorId;
          el.className = "invalid-feedback d-block";
          phoneInput.parentElement.appendChild(el);
        }
        el.textContent = "Telefone deve conter DDD + número (10 ou 11 dígitos).";
        phoneInput.classList.add("is-invalid");
      } else {
        if (el) el.textContent = "";
        phoneInput.classList.remove("is-invalid");
      }
    });
  }

  // Campo CEP
  const zipInput = document.querySelector('[name="signup[company][zip_code]"]');
  if (zipInput) {
    const errorId = "company_zip_error";
    const ensureErrorEl = () => {
      let el = document.getElementById(errorId);
      if (!el) {
        el = document.createElement("div");
        el.id = errorId;
        el.className = "invalid-feedback d-block";
        zipInput.parentElement.appendChild(el);
      }
      return el;
    };
    const showError = (msg) => {
      const el = ensureErrorEl();
      el.textContent = msg;
      zipInput.classList.add("is-invalid");
    };
    const clearError = () => {
      const el = document.getElementById(errorId);
      if (el) el.textContent = "";
      zipInput.classList.remove("is-invalid");
    };

    // máscara enquanto digita
    zipInput.addEventListener("input", () => {
      const prev = zipInput.value;
      zipInput.value = formatCEP(prev);
      zipInput.setSelectionRange(zipInput.value.length, zipInput.value.length);
    });

    // valida ao sair
    zipInput.addEventListener("blur", () => {
      if (onlyDigits(zipInput.value).length !== 8) {
        showError("CEP inválido. Use o formato 00000-000.");
      } else {
        clearError();
      }
    });

    // bloquear avanço do step se CEP inválido
    document.querySelectorAll('[onclick="stepper1.next()"]').forEach((btn) => {
      btn.addEventListener("click", function (e) {
        const pane = btn.closest("#step-company");
        if (!pane) return;
        if (onlyDigits(zipInput.value).length !== 8) {
          e.preventDefault();
          showError("CEP inválido. Use o formato 00000-000.");
          zipInput.focus();
        }
      });
    });
  }
});