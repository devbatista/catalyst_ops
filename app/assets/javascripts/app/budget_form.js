function parseBudgetNumber(rawValue) {
  const raw = String(rawValue || "").trim();
  if (!raw) return 0;

  let sanitized = raw.replace(/[^\d,.\-]/g, "");
  if (!sanitized) return 0;

  const hasComma = sanitized.includes(",");
  const hasDot = sanitized.includes(".");

  if (hasComma && hasDot) {
    if (sanitized.lastIndexOf(",") > sanitized.lastIndexOf(".")) {
      sanitized = sanitized.replace(/\./g, "").replace(",", ".");
    } else {
      sanitized = sanitized.replace(/,/g, "");
    }
  } else if (hasComma) {
    sanitized = sanitized.replace(/\./g, "").replace(",", ".");
  } else {
    sanitized = sanitized.replace(/,/g, "");
  }

  const parsed = Number(sanitized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function formatBudgetCurrency(value) {
  return Number(value || 0).toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

function calculateBudgetTotal() {
  const totalInput = document.querySelector('input[name="budget[total_value]"]');
  if (!totalInput) return;

  const rows = document.querySelectorAll("#service-items-list .input-group, #service-items-list .service-item-row");
  let total = 0;

  rows.forEach((row) => {
    if (row.style.display === "none") return;

    const destroyFlag = row.querySelector(".service-item-destroy-flag");
    if (destroyFlag && destroyFlag.value === "1") return;

    const quantityInput = row.querySelector('input[name*="[quantity]"]');
    const unitPriceInput = row.querySelector('input[name*="[unit_price]"]');
    if (!quantityInput || !unitPriceInput) return;

    const quantity = parseBudgetNumber(quantityInput.value);
    const unitPrice = parseBudgetNumber(unitPriceInput.value);
    total += quantity * unitPrice;
  });

  totalInput.value = formatBudgetCurrency(total);
}

function isBudgetItemField(target) {
  return target.matches('input[name*="budget[service_items_attributes]"][name$="[quantity]"], input[name*="budget[service_items_attributes]"][name$="[unit_price]"]');
}

document.addEventListener("input", function (e) {
  const isBudgetItem = isBudgetItemField(e.target);
  if (!isBudgetItem) return;

  calculateBudgetTotal();
});

document.addEventListener("change", function (e) {
  const isBudgetItem = isBudgetItemField(e.target);
  if (!isBudgetItem) return;

  calculateBudgetTotal();
});

document.addEventListener("click", function (e) {
  if (e.target.matches("#add-service-item")) {
    setTimeout(calculateBudgetTotal, 0);
    return;
  }

  if (e.target.matches(".remove-item") || e.target.closest(".remove-item")) {
    setTimeout(calculateBudgetTotal, 0);
  }
});

document.addEventListener("DOMContentLoaded", calculateBudgetTotal);
document.addEventListener("turbo:load", calculateBudgetTotal);
