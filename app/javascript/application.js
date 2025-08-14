import "@hotwired/turbo-rails"
import "./controllers"

import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery

import "select2"
import "metisMenu"
import PerfectScrollbar from "perfect-scrollbar"

// --- 1. CONFIGURAÇÃO ÚNICA DE EVENTOS (Executa apenas uma vez) ---
// Estes listeners são adicionados ao corpo do documento e funcionam para
// elementos que são adicionados dinamicamente à página.
document.addEventListener('click', function(e) {
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


// --- 2. FUNÇÕES DE INICIALIZAÇÃO (Chamadas a cada navegação) ---

function initializePlugins() {
  $(document).ready(function() {
    // Inicializa o MetisMenu (menu lateral)
    const menuEl = $('#menu');
    if (menuEl.length > 0 && $.fn.metisMenu) {
      if (menuEl.data('metisMenu')) menuEl.metisMenu('dispose');
      menuEl.metisMenu();
    }

    // Inicializa o Select2 para os técnicos
    const selectField = $('#multiple-select-field');
    if (selectField.length > 0 && $.fn.select2) {
      selectField.select2({
        theme: 'bootstrap-5',
        placeholder: selectField.data('placeholder'),
        width: '100%'
      });
    }
  });

  // Inicializa as barras de rolagem
  $('.app-container, .header-message-list, .header-notifications-list').each(function() {
    const ps = PerfectScrollbar.getInstance(this);
    if (ps) ps.destroy();
    new PerfectScrollbar(this);
  });
  
  $('.js-wait').show();
}


// --- 3. EVENTOS DO TURBO ---

document.addEventListener("turbo:load", () => {
  initializePlugins();
});

document.addEventListener("turbo:before-cache", () => {
  // Destrói a instância do Select2 para evitar problemas ao voltar na página
  const selectField = $('#order_service_user_ids');
  if (selectField.length > 0 && selectField.data('select2')) {
    selectField.select2('destroy');
  }
});