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

  // Helpers CPF/CNPJ
  const onlyDigits = (v) => (v || "").replace(/\D/g, "");
  const isAllEqual = (s) => /^(\d)\1+$/.test(s);

  // Formatadores
  function formatCPF(value) {
    const v = onlyDigits(value).slice(0, 11);
    const parts = [];
    if (v.length > 3) parts.push(v.slice(0, 3));
    if (v.length > 6) parts.push(v.slice(3, 6));
    if (v.length > 9) parts.push(v.slice(6, 9));
    let last = v.slice(9);
    let formatted = "";
    if (v.length <= 3) formatted = v;
    else if (v.length <= 6) formatted = `${v.slice(0,3)}.${v.slice(3)}`;
    else if (v.length <= 9) formatted = `${v.slice(0,3)}.${v.slice(3,6)}.${v.slice(6)}`;
    else formatted = `${v.slice(0,3)}.${v.slice(3,6)}.${v.slice(6,9)}-${v.slice(9)}`;
    return formatted;
  }

  function formatCNPJ(value) {
    const v = onlyDigits(value).slice(0, 14);
    if (v.length <= 2) return v;
    if (v.length <= 5) return `${v.slice(0,2)}.${v.slice(2)}`;
    if (v.length <= 8) return `${v.slice(0,2)}.${v.slice(2,5)}.${v.slice(5)}`;
    if (v.length <= 12) return `${v.slice(0,2)}.${v.slice(2,5)}.${v.slice(5,8)}/${v.slice(8)}`;
    return `${v.slice(0,2)}.${v.slice(2,5)}.${v.slice(5,8)}/${v.slice(8,12)}-${v.slice(12)}`;
  }

  function formatDoc(value) {
    const digits = onlyDigits(value);
    return digits.length <= 11 ? formatCPF(digits) : formatCNPJ(digits);
  }

  // Validações
  function validateCPF(cpf) {
    cpf = onlyDigits(cpf);
    if (cpf.length !== 11 || isAllEqual(cpf)) return false;
    let sum = 0;
    for (let i = 0; i < 9; i++) sum += parseInt(cpf[i], 10) * (10 - i);
    let d1 = 11 - (sum % 11);
    d1 = d1 > 9 ? 0 : d1;
    if (d1 !== parseInt(cpf[9], 10)) return false;

    sum = 0;
    for (let i = 0; i < 10; i++) sum += parseInt(cpf[i], 10) * (11 - i);
    let d2 = 11 - (sum % 11);
    d2 = d2 > 9 ? 0 : d2;
    return d2 === parseInt(cpf[10], 10);
  }

  function validateCNPJ(cnpj) {
    cnpj = onlyDigits(cnpj);
    if (cnpj.length !== 14 || isAllEqual(cnpj)) return false;
    const calcDigit = (base) => {
      let sum = 0, pos = base - 7;
      for (let i = base; i >= 1; i--) {
        sum += parseInt(cnpj[base - i], 10) * pos--;
        if (pos < 2) pos = 9;
      }
      const res = sum % 11 < 2 ? 0 : 11 - (sum % 11);
      return res;
    };
    const d1 = calcDigit(12);
    if (d1 !== parseInt(cnpj[12], 10)) return false;
    const d2 = calcDigit(13);
    return d2 === parseInt(cnpj[13], 10);
  }

  function validateDoc(value) {
    const digits = onlyDigits(value);
    if (digits.length <= 11) return validateCPF(digits);
    return validateCNPJ(digits);
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
    docInput.addEventListener("input", function (e) {
      const cursorPos = docInput.selectionStart;
      const prev = docInput.value;
      docInput.value = formatDoc(prev);

      // Ajuste simples do cursor ao fim (evita pular no meio)
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

  // Formatador de telefone (Brasil)
  const onlyDigitsPhone = (v) => (v || "").replace(/\D/g, "");

  function formatPhone(value) {
    const v = onlyDigitsPhone(value).slice(0, 11); // 10 ou 11 dígitos
    const ddd = v.slice(0, 2);

    if (v.length <= 2) return `(${v}`;
    if (v.length <= 6) return `(${ddd}) ${v.slice(2)}`;
    if (v.length <= 10) return `(${ddd}) ${v.slice(2, 6)}-${v.slice(6)}`;
    return `(${ddd}) ${v.slice(2, 7)}-${v.slice(7)}`;
  }

  // Campo telefone
  const phoneInput = document.querySelector('[name="signup[company][phone]"]');
  if (phoneInput) {
    phoneInput.addEventListener("input", function () {
      const prev = phoneInput.value;
      phoneInput.value = formatPhone(prev);
      phoneInput.setSelectionRange(phoneInput.value.length, phoneInput.value.length);
    });

    // validação simples: 10 ou 11 dígitos
    phoneInput.addEventListener("blur", function () {
      const digits = onlyDigitsPhone(phoneInput.value);
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
});