(function () {
  const UNIT_SELECTOR = 'input[name*="budget[service_items_attributes]"][name$="[unit_price]"]';
  const QTY_SELECTOR = 'input[name*="budget[service_items_attributes]"][name$="[quantity]"]';
  const ROW_SELECTOR = '#service-items-list .input-group, #service-items-list .service-item-row';
  const TOTAL_SELECTOR = 'input[name="budget[total_value]"]';

  function parseQty(raw) {
    const s = String(raw || '').trim().replace(/[^\d,.\-]/g, '');
    if (!s) return 0;

    const n = Number(s.replace(/\./g, '').replace(',', '.'));
    return Number.isFinite(n) ? n : 0;
  }

  function parseMoneyMasked(raw) {
    const digits = String(raw || '').replace(/\D/g, '');
    return digits ? Number(digits) / 100 : 0;
  }

  function formatBRL(n) {
    return Number(n || 0).toLocaleString('pt-BR', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  function calculateBudgetTotal() {
    const totalInput = document.querySelector(TOTAL_SELECTOR);
    if (!totalInput) return;

    let total = 0;

    document.querySelectorAll(ROW_SELECTOR).forEach((row) => {
      if (row.style.display === 'none') return;

      const destroyFlag = row.querySelector('.service-item-destroy-flag');
      if (destroyFlag && destroyFlag.value === '1') return;

      const quantityInput = row.querySelector(QTY_SELECTOR);
      const unitPriceInput = row.querySelector(UNIT_SELECTOR);
      if (!quantityInput || !unitPriceInput) return;

      total += parseQty(quantityInput.value) * parseMoneyMasked(unitPriceInput.value);
    });

    totalInput.value = formatBRL(total);
  }

  function scheduleBudgetTotalCalculation() {
    calculateBudgetTotal();
    setTimeout(calculateBudgetTotal, 20);
    setTimeout(calculateBudgetTotal, 80);
  }

  function handleFieldEvent(e) {
    const target = e.target;
    if (!(target instanceof HTMLInputElement)) return;
    if (!target.matches(UNIT_SELECTOR) && !target.matches(QTY_SELECTOR)) return;

    scheduleBudgetTotalCalculation();
  }

  document.addEventListener('input', handleFieldEvent, true);
  document.addEventListener('keyup', handleFieldEvent, true);
  document.addEventListener('change', handleFieldEvent, true);

  document.addEventListener('click', function (e) {
    if (e.target.matches('#add-service-item')) {
      scheduleBudgetTotalCalculation();
      return;
    }

    if (e.target.matches('.remove-item') || e.target.closest('.remove-item')) {
      scheduleBudgetTotalCalculation();
    }
  }, true);

  document.addEventListener('DOMContentLoaded', calculateBudgetTotal);
  document.addEventListener('turbo:load', calculateBudgetTotal);
})();
