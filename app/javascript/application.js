if (window.Rails && typeof window.Rails.start === "function") {
  window.Rails.start()
}

import "controllers"

import "jquery"

import "select2"
import "metisMenu"
import PerfectScrollbar from "perfect-scrollbar"

import "register/signups"

document.addEventListener('click', function (e) {
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
  const currentUrl = window.location.href;
  const menuLinks = $("#menu li a");
  let bestMatch = null;

  menuLinks.each(function () {
    const linkHref = this.href;
    if (currentUrl.startsWith(linkHref)) {
      if (!bestMatch || linkHref.length > bestMatch.href.length) {
        bestMatch = this;
      }
    }
  });

  $("#menu li").removeClass('mm-active active');
  menuLinks.removeClass('active');

  if (bestMatch) {
    const activeLink = $(bestMatch);
    activeLink.addClass('active');

    const parentLi = activeLink.closest('li');
    parentLi.addClass('mm-active').addClass('active');

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
});