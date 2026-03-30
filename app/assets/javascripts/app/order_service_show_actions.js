document.addEventListener("submit", function (event) {
  const form = event.target;
  if (!(form instanceof HTMLFormElement)) return;
  if (form.dataset.osActionConfirm !== "true") return;

  const message =
    form.dataset.confirmMessage ||
    "Tem certeza que deseja executar esta ação na OS?";

  if (!window.confirm(message)) {
    event.preventDefault();
  }
});
