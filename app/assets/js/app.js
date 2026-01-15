// --- Funções de Inicialização Segura de Plugins ---

function initializeMetisMenu() {
  const menuEl = $('#menu');
  if (menuEl.length === 0) return; // Sai se o menu não existir na página

  // Se o plugin não estiver pronto, espera 50ms e tenta de novo
  if (!$.fn.metisMenu) {
    setTimeout(initializeMetisMenu, 50);
    return;
  }

  // Destrói a instância antiga para evitar erros
  if (menuEl.data('metisMenu')) {
    menuEl.metisMenu('dispose');
  }
  
  // Inicializa a nova instância
  menuEl.metisMenu();
}

function initializePerfectScrollbars() {
  // Se o plugin não estiver pronto, espera 50ms e tenta de novo
  if (typeof PerfectScrollbar === 'undefined') {
    setTimeout(initializePerfectScrollbars, 50);
    return;
  }

  $('.app-container, .header-message-list, .header-notifications-list').each(function() {
    // Destrói a instância antiga
    const ps = PerfectScrollbar.getInstance(this);
    if (ps) {
      ps.destroy();
    }
    // Cria a nova instância
    new PerfectScrollbar(this);
  });
}

function setActiveMenuLink() {
  // Esta parte não depende de plugin, então é segura
  var e = window.location;
  var o = $(".metismenu li a").filter(function() {
    return this.href == e;
  }).addClass("").parent().addClass("mm-active");
  while (o.is("li")) {
    o = o.parent("").addClass("mm-show").parent("").addClass("mm-active");
  }
}

function initializeSelect2() {
    const selectFields = $('.select2-field');
    if (selectFields.length === 0) return;

    if (!$.fn.select2) {
        setTimeout(initializeSelect2, 50);
        return;
    }
    selectFields.select2({
        theme: 'bootstrap-5'
    });
}

// --- Listeners de Eventos (Delegação) ---
// Estes são definidos uma única vez e funcionam em todas as páginas
$(document).off('.app-events').on("click.app-events", ".mobile-search-icon", function() {
    $(".search-bar").addClass("full-search-bar");
}).on("click.app-events", ".search-close", function() {
    $(".search-bar").removeClass("full-search-bar");
}).on("click.app-events", ".mobile-toggle-menu", function() {
    // antes: $(".wrapper").addClass("toggled");
    $(".wrapper").toggleClass("toggled"); // abre se estiver fechado, fecha se estiver aberto
}).on("click.app-events", ".toggle-icon", function() {
    $(".wrapper").toggleClass("toggled");
}).on("click.app-events", ".switcher-btn", function() {
    $(".switcher-wrapper").toggleClass("switcher-toggled");
}).on("click.app-events", ".close-switcher", function() {
    $(".switcher-wrapper").removeClass("switcher-toggled");
});
// Adicione outros eventos de clique simples aqui...


// --- Evento Principal do Turbo ---
document.addEventListener("turbo:load", function() {
  console.log("Turbo loaded, initializing app plugins...");
  
  // Chama as funções de inicialização segura
  initializeMetisMenu();
  initializePerfectScrollbars();
  setActiveMenuLink();
  initializeSelect2(); // Essencial para o seu formulário
});

// --- Limpeza antes do Cache do Turbo ---
document.addEventListener("turbo:before-cache", function() {
  // Destrói o Select2 para evitar problemas de estado
  const selectFields = $('.select2-field');
  if (selectFields.length > 0 && $.fn.select2) {
    selectFields.select2('destroy');
  }
});