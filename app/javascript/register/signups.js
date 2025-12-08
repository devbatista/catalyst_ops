document.addEventListener("DOMContentLoaded", function () {
  // Init BS Stepper
  const el = document.querySelector("#stepper1");
  if (el && window.Stepper) {
    window.stepper1 = new window.Stepper(el, { linear: false, animation: true });
  }

  // Password show/hide
  function bindToggle(containerSelector) {
    var container = document.querySelector(containerSelector);
    if (!container) return;
    var toggle = container.querySelector("a");
    var input = container.querySelector("input");
    var icon = container.querySelector("i");
    if (toggle && input && icon) {
      toggle.addEventListener("click", function (event) {
        event.preventDefault();
        if (input.type === "text") {
          input.type = "password";
          icon.classList.add("bx-hide");
          icon.classList.remove("bx-show");
        } else {
          input.type = "text";
          icon.classList.remove("bx-hide");
          icon.classList.add("bx-show");
        }
      });
    }
  }

  bindToggle("#show_hide_password");
  bindToggle("#show_hide_password_conf");
});