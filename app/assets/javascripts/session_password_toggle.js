(function () {
  function bindPasswordToggle(toggle) {
    if (toggle.dataset.passwordToggleBound === "true") return;

    var group = toggle.closest(".input-group");
    if (!group) return;

    var input = group.querySelector("input");
    var icon = toggle.querySelector("i");
    if (!input || !icon) return;

    toggle.dataset.passwordToggleBound = "true";
    toggle.addEventListener("click", function (event) {
      event.preventDefault();

      var isVisible = input.type === "text";
      input.type = isVisible ? "password" : "text";
      icon.classList.toggle("bx-hide", isVisible);
      icon.classList.toggle("bx-show", !isVisible);
      toggle.setAttribute("aria-label", isVisible ? "Mostrar senha" : "Ocultar senha");
    });
  }

  function initializePasswordToggles() {
    document.querySelectorAll(".js-password-toggle").forEach(bindPasswordToggle);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializePasswordToggles);
  } else {
    initializePasswordToggles();
  }
})();
