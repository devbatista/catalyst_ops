import "@hotwired/turbo-rails"
import "./controllers"

import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery

import "select2"
import "metisMenu"
import PerfectScrollbar from "perfect-scrollbar"

// --- 1. CONFIGURAÇÃO ÚNICA DE EVENTOS (Executa apenas uma vez) ---
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


// --- NOVA VERSÃO ---
// Função para definir o item de menu ativo com base na URL atual
// Agora funciona para sub-páginas como /clients/new
function setActiveMenuItem() {
  const currentUrl = window.location.href;
  const menuLinks = $("#menu li a");
  let bestMatch = null;

  // Encontra o link com o prefixo mais longo que corresponde à URL atual
  menuLinks.each(function() {
    const linkHref = this.href;
    if (currentUrl.startsWith(linkHref)) {
      if (!bestMatch || linkHref.length > bestMatch.href.length) {
        bestMatch = this;
      }
    }
  });

  // Remove a classe 'active' e 'mm-active' de todos os itens primeiro
  $("#menu li").removeClass('mm-active active');
  menuLinks.removeClass('active');

  if (bestMatch) {
    const activeLink = $(bestMatch);
    activeLink.addClass('active');
    
    const parentLi = activeLink.closest('li');
    parentLi.addClass('mm-active').addClass('active');

    // Abre os submenus pais, se houver
    let parentUl = parentLi.parent('ul.metismenu-container');
    while (parentUl.length > 0 && !parentUl.is('#menu')) {
      parentUl.addClass('mm-show');
      const grandParentLi = parentUl.parent('li');
      grandParentLi.addClass('mm-active');
      parentUl = grandParentLi.parent('ul.metismenu-container');
    }
  }
}

// --- 2. FUNÇÕES DE INICIALIZAÇÃO (Chamadas a cada navegação) ---

function initializePage() {
  // Inicializa as barras de rolagem
  $('.app-container, .header-message-list, .header-notifications-list').each(function() {
    const ps = PerfectScrollbar.getInstance(this);
    if (ps) ps.destroy();
    new PerfectScrollbar(this);
  });

  // Usa o document.ready para garantir que o DOM está pronto para os plugins jQuery
  $(document).ready(function() {
    // 1. Inicializa o MetisMenu (menu lateral)
    const menuEl = $('#menu');
    if (menuEl.length > 0 && $.fn.metisMenu) {
      if (menuEl.data('metisMenu')) menuEl.metisMenu('dispose');
      menuEl.metisMenu();
    }

    // 2. Inicializa o Select2 para os técnicos
    const selectField = $('#multiple-select-field');
    if (selectField.length > 0 && $.fn.select2) {
      selectField.select2({
        theme: 'bootstrap-5',
        placeholder: selectField.data('placeholder'),
        width: '100%'
      });
    }

    // 3. Renderiza o calendário

    // 4. Define o item de menu ativo
    setActiveMenuItem();

    // 5. Exibe o conteúdo após a inicialização dos plugins
    $('.js-wait').show();
  });
}


// --- 3. EVENTOS DO TURBO ---

document.addEventListener("turbo:load", () => {
  initializePage();
});

document.addEventListener("turbo:before-cache", () => {
  // CORREÇÃO: Use o ID correto para destruir a instância do Select2
  const selectField = $('#multiple-select-field');
  if (selectField.length > 0 && selectField.data('select2')) {
    selectField.select2('destroy');
  }
});