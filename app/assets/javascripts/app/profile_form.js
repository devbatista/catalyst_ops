document.addEventListener("DOMContentLoaded", function () {
  const formatProfilePhone = (value) => {
    const digits = String(value || "").replace(/\D/g, "").slice(0, 11);
    if (digits.length <= 2) return digits;
    if (digits.length <= 7) return `(${digits.slice(0, 2)}) ${digits.slice(2)}`;
    return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7)}`;
  };

  document.querySelectorAll('input[data-mask="phone"]').forEach(input => {
    input.value = formatProfilePhone(input.value);

    input.addEventListener("input", function () {
      input.value = formatProfilePhone(input.value);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });
});
