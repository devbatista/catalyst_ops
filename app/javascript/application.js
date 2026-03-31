if (window.Rails && typeof window.Rails.start === "function") {
  window.Rails.start()
}

import "controllers"

import "jquery"

import "select2"
import "metisMenu"
import PerfectScrollbar from "perfect-scrollbar"

import "register/signups"

function formatCurrencyBR(rawValue) {
  const digits = String(rawValue || "").replace(/\D/g, "");
  if (!digits) return "";

  const value = Number(digits) / 100;
  return value.toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

function parseCurrencyToNumber(rawValue) {
  const raw = String(rawValue || "").trim();
  if (!raw) return null;

  let sanitized = raw.replace(/[^\d,.\-]/g, "");
  if (!sanitized) return null;

  const hasComma = sanitized.includes(",");
  const hasDot = sanitized.includes(".");

  if (hasComma && hasDot) {
    if (sanitized.lastIndexOf(",") > sanitized.lastIndexOf(".")) {
      // 1.234,56 -> 1234.56
      sanitized = sanitized.replace(/\./g, "").replace(",", ".");
    } else {
      // 1,234.56 -> 1234.56
      sanitized = sanitized.replace(/,/g, "");
    }
  } else if (hasComma) {
    // 123,45 -> 123.45
    sanitized = sanitized.replace(/\./g, "").replace(",", ".");
  } else {
    // 1234.56 ou 1234
    sanitized = sanitized.replace(/,/g, "");
  }

  const parsed = Number(sanitized);
  return Number.isFinite(parsed) ? parsed : null;
}

function formatNumberToCurrencyBR(value) {
  return Number(value).toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

function maskCurrencyInput(input) {
  if (!input) return;
  input.value = formatCurrencyBR(input.value);
  input.setSelectionRange(input.value.length, input.value.length);
}

function initializeCurrencyMasks() {
  document.querySelectorAll('input[data-money-mask="brl"]').forEach((input) => {
    const parsed = parseCurrencyToNumber(input.value);
    if (parsed !== null) {
      input.value = formatNumberToCurrencyBR(parsed);
    }
  });
}


document.addEventListener("input", function (e) {
  if (!e.target.matches('input[data-money-mask="brl"]')) return;
  maskCurrencyInput(e.target);
});

document.addEventListener('click', async function (e) {
  // Logout via DELETE usando JavaScript
  const logoutLink = e.target.closest('a.js-logout')
  if (logoutLink) {
    e.preventDefault()

    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content')

    try {
      const resp = await fetch(logoutLink.href, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': csrfToken || '',
          'Accept': 'text/html,application/xhtml+xml'
        },
        credentials: 'same-origin',
        redirect: 'manual'
      })

      if (resp.status === 302 || resp.status === 303) {
        const location = resp.headers.get('Location')
        if (location) {
          window.location.href = location
          return
        }
      }

      window.location.href = '/'
    } catch (_err) {
      window.location.href = '/'
    }

    return
  }

  // Botão de adicionar item de serviço
  if (e.target.matches('#add-service-item')) {
    e.preventDefault();
    const serviceItemsContainer = document.getElementById('service-items-list');
    if (serviceItemsContainer) {
      let template = document.getElementById('service-item-template').innerHTML;
      let newIndex = new Date().getTime();
      let newRow = template.replace(/NEW_INDEX/g, newIndex);
      serviceItemsContainer.insertAdjacentHTML('beforeend', newRow);
    }
  }

  // Botão de remover item de serviço
  if (e.target.matches('.remove-item') || e.target.closest('.remove-item')) {
    e.preventDefault();
    const row = e.target.closest('.input-group, .service-item-row');
    const destroyFlag = row.querySelector('.service-item-destroy-flag');
    if (destroyFlag) {
      destroyFlag.value = '1';
      row.style.display = 'none';
    } else {
      row.remove();
    }
  }
});

function setActiveMenuItem() {
  const menu = $('#menu');
  if (menu.length === 0) return;

  const currentActiveLis = menu.find('li.active');

  // Se o servidor já marcou algum <li> como active, apenas garante os pais abertos
  if (currentActiveLis.length > 0) {
    currentActiveLis.each(function () {
      const li = $(this);

      // abre todos os uls ancestrais (submenus)
      li.parents('ul').each(function () {
        const ul = $(this);
        if (!ul.is('#menu')) {
          ul.addClass('mm-show');
          ul.parent('li').addClass('mm-active');
        }
      });
    });
    return;
  }

  // Se não tiver nada ativo vindo do servidor, cai no comportamento antigo:
  const currentUrl = window.location.href;
  const menuLinks = menu.find("li a");
  let bestMatch = null;

  menuLinks.each(function () {
    const linkHref = this.href;
    if (currentUrl.startsWith(linkHref)) {
      if (!bestMatch || linkHref.length > bestMatch.href.length) {
        bestMatch = this;
      }
    }
  });

  menu.find("li").removeClass('mm-active active');
  menuLinks.removeClass('active');

  if (bestMatch) {
    const activeLink = $(bestMatch);
    activeLink.addClass('active');

    const parentLi = activeLink.closest('li');
    parentLi.addClass('mm-active active');

    let parentUl = parentLi.parent('ul.metismenu-container');
    while (parentUl.length > 0 && !parentUl.is('#menu')) {
      parentUl.addClass('mm-show');
      const grandParentLi = parentUl.parent('li');
      grandParentLi.addClass('mm-active');
      parentUl = grandParentLi.parent('ul.metismenu-container');
    }
  }
}

function initializePage() {
  $('.app-container, .header-message-list, .header-notifications-list').each(function () {
    const ps = PerfectScrollbar.getInstance(this);
    if (ps) ps.destroy();
    new PerfectScrollbar(this);
  });

  const menuEl = $('#menu');
  if (menuEl.length > 0 && $.fn.metisMenu) {
    if (menuEl.data('metisMenu')) menuEl.metisMenu('dispose');
    menuEl.metisMenu();
  }

  const selectField = $('#multiple-select-field');
  if (selectField.length > 0 && $.fn.select2) {
    selectField.select2({
      theme: 'bootstrap-5',
      placeholder: selectField.data('placeholder'),
      width: '100%'
    });
  }

  const chartCanvas = document.getElementById('chart2');
  if (chartCanvas) {
    const statusListItems = document.querySelectorAll('#os-status-list li');
    const labels = [];
    const data = [];
    const backgroundColors = [];

    const colorMap = {
      'primary': '#0d6efd',
      'secondary': '#6c757d',
      'success': '#198754',
      'danger': '#dc3545',
      'warning': '#ffc107',
      'info': '#0dcaf0',
      'dark': '#343a40',
      'light': '#f8f9fa'
    };

    statusListItems.forEach(item => {
      labels.push(item.dataset.status);
      data.push(parseInt(item.dataset.count, 10));
      const colorKey = item.dataset.colorKey.replace('bg-', '');
      backgroundColors.push(colorMap[colorKey] || '#6c757d');
    });

    const ctx = chartCanvas.getContext('2d');
    new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{
          backgroundColor: backgroundColors,
          data: data,
          borderWidth: 0
        }]
      },
      options: {
        maintainAspectRatio: false,
        responsive: true,
        plugins: {
          legend: {
            display: false
          }
        },
        cutout: '70%'
      }
    });
  }

  setActiveMenuItem();

  $('.js-wait').show();
}

$(document).ready(function () {
  initializePage();
  initializeCurrencyMasks();
});
