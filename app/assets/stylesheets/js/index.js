// Declara as variáveis no objeto global 'window' para que persistam e
// não causem erro de "already been declared" se o script for carregado novamente.
window.chart1Instance = window.chart1Instance || null;
window.chart2Instance = window.chart2Instance || null;
window.chart3Instance = window.chart3Instance || null;
window.chart4Instance = window.chart4Instance || null;
window.chart5Instance = window.chart5Instance || null;

// Função para inicializar o jVectorMap de forma segura
function initializeVectorMap() {
  const mapEl = jQuery('#geographic-map-2');
  if (mapEl.length === 0) {
    return; // Não há mapa nesta página, então não faz nada.
  }

  // Verifica se o plugin está pronto. Se não, espera 100ms e tenta de novo.
  if (!jQuery.fn.vectorMap) {
    setTimeout(initializeVectorMap, 100);
    return;
  }

  mapEl.empty(); // Limpa o conteúdo do mapa antes de recriar
  mapEl.vectorMap({
    map: 'world_mill_en',
    backgroundColor: 'transparent',
    borderColor: '#818181',
    borderOpacity: 0.25,
    borderWidth: 1,
    zoomOnScroll: false,
    color: '#009efb',
    regionStyle: { initial: { fill: '#008cff' } },
    markerStyle: { initial: { r: 9, 'fill': '#fff', 'fill-opacity': 1, 'stroke': '#000', 'stroke-width': 5, 'stroke-opacity': 0.4 } },
    enableZoom: true,
    hoverColor: '#009efb',
    markers: [{ latLng: [21.00, 78.00], name: 'Lorem Ipsum Dollar' }],
    hoverOpacity: null,
    normalizeFunction: 'linear',
    scaleColors: ['#b6d6ff', '#005ace'],
    selectedColor: '#c9dfaf',
    selectedRegions: [],
    showTooltip: true,
  });
}


document.addEventListener("turbo:load", function() {
  "use strict";

  // --- GRÁFICOS ---
  // (O código dos gráficos permanece o mesmo, destruindo e recriando as instâncias)

  // chart 1
  const chart1El = document.getElementById("chart1");
  if (chart1El) {
    if (window.chart1Instance) {
      window.chart1Instance.destroy();
    }
    const ctx = chart1El.getContext('2d');
    const gradientStroke1 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke1.addColorStop(0, '#6078ea');
    gradientStroke1.addColorStop(1, '#17c5ea');
    const gradientStroke2 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke2.addColorStop(0, '#ff8359');
    gradientStroke2.addColorStop(1, '#ffdf40');
    
    window.chart1Instance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        datasets: [{
          label: 'Laptops',
          data: [65, 59, 80, 81, 65, 59, 80, 81, 59, 80, 81, 65],
          borderColor: gradientStroke1,
          backgroundColor: gradientStroke1,
          hoverBackgroundColor: gradientStroke1,
          pointRadius: 0,
          fill: false,
          borderRadius: 20,
          borderWidth: 0
        }, {
          label: 'Mobiles',
          data: [28, 48, 40, 19, 28, 48, 40, 19, 40, 19, 28, 48],
          borderColor: gradientStroke2,
          backgroundColor: gradientStroke2,
          hoverBackgroundColor: gradientStroke2,
          pointRadius: 0,
          fill: false,
          borderRadius: 20,
          borderWidth: 0
        }]
      },
      options: {
        maintainAspectRatio: false,
        barPercentage: 0.5,
        categoryPercentage: 0.8,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
      }
    });
  }

  // chart 2 (Dinâmico)
  const chart2El = document.getElementById("chart2");
  if (chart2El) {
    if (window.chart2Instance) {
      window.chart2Instance.destroy();
    }
    const ctx = chart2El.getContext('2d');
    const statusLabels = [];
    const statusCounts = [];
    const statusColors = [];

    $('#os-status-list li').each(function() {
      statusLabels.push($(this).find('.os-status-label').text());
      statusCounts.push(parseInt($(this).find('.os-status-count').text(), 10));
      const badge = $(this).find('.os-status-count')[0];
      const color = window.getComputedStyle(badge).backgroundColor;
      statusColors.push(color);
    });

    window.chart2Instance = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: statusLabels,
        datasets: [{
          backgroundColor: statusColors,
          hoverBackgroundColor: statusColors,
          data: statusCounts,
          borderWidth: 1
        }]
      },
      options: {
        maintainAspectRatio: false,
        cutout: 82,
        plugins: { legend: { display: false } }
      }
    });
  }

  // --- MAPA ---
  // Chama a função segura para inicializar o mapa.
  initializeVectorMap();

  // chart 3
  const chart3El = document.getElementById('chart3');
  if (chart3El) {
    if (window.chart3Instance) {
      window.chart3Instance.destroy();
    }
    const ctx = chart3El.getContext('2d');
    const gradientStroke1 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke1.addColorStop(0, '#00b09b');
    gradientStroke1.addColorStop(1, '#96c93d');
    window.chart3Instance = new Chart(ctx, {
      type: 'line',
      data: {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [{
          label: 'Facebook',
          data: [5, 30, 16, 23, 8, 14, 2],
          backgroundColor: [gradientStroke1],
          fill: { target: 'origin', above: 'rgb(21 202 32 / 15%)' },
          tension: 0.4,
          borderColor: [gradientStroke1],
          borderWidth: 3
        }]
      },
      options: {
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
      }
    });
  }

  // chart 4
  const chart4El = document.getElementById("chart4");
  if (chart4El) {
    if (window.chart4Instance) {
      window.chart4Instance.destroy();
    }
    const ctx = chart4El.getContext('2d');
    const gradientStroke1 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke1.addColorStop(0, '#ee0979');
    gradientStroke1.addColorStop(1, '#ff6a00');
    const gradientStroke2 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke2.addColorStop(0, '#283c86');
    gradientStroke2.addColorStop(1, '#39bd3c');
    const gradientStroke3 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke3.addColorStop(0, '#7f00ff');
    gradientStroke3.addColorStop(1, '#e100ff');
    window.chart4Instance = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: ["Completed", "Pending", "Process"],
        datasets: [{
          backgroundColor: [gradientStroke1, gradientStroke2, gradientStroke3],
          hoverBackgroundColor: [gradientStroke1, gradientStroke2, gradientStroke3],
          data: [50, 50, 50],
          borderWidth: [1, 1, 1]
        }]
      },
      options: {
        maintainAspectRatio: false,
        cutout: 95,
        plugins: { legend: { display: false } }
      }
    });
  }

  // chart 5
  const chart5El = document.getElementById("chart5");
  if (chart5El) {
    if (window.chart5Instance) {
      window.chart5Instance.destroy();
    }
    const ctx = chart5El.getContext('2d');
    const gradientStroke1 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke1.addColorStop(0, '#f54ea2');
    gradientStroke1.addColorStop(1, '#ff7676');
    const gradientStroke2 = ctx.createLinearGradient(0, 0, 0, 300);
    gradientStroke2.addColorStop(0, '#42e695');
    gradientStroke2.addColorStop(1, '#3bb2b8');
    window.chart5Instance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: [1, 2, 3, 4, 5],
        datasets: [{
          label: 'Clothing',
          data: [40, 30, 60, 35, 60],
          borderColor: gradientStroke1,
          backgroundColor: gradientStroke1,
          hoverBackgroundColor: gradientStroke1,
          pointRadius: 0,
          fill: false,
          borderWidth: 1
        }, {
          label: 'Electronic',
          data: [50, 60, 40, 70, 35],
          borderColor: gradientStroke2,
          backgroundColor: gradientStroke2,
          hoverBackgroundColor: gradientStroke2,
          pointRadius: 0,
          fill: false,
          borderWidth: 1
        }]
      },
      options: {
        maintainAspectRatio: false,
        barPercentage: 0.5,
        categoryPercentage: 0.8,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
      }
    });
  }
});