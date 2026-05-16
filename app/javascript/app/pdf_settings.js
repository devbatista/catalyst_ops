function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.getAttribute("content") || "";
}

function redirectUrl() {
  return document.querySelector(".pdf-settings-panel")?.dataset.redirectUrl || "/configurations?tab=pdf";
}

document.addEventListener("change", function(event) {
  if (!event.target.classList.contains("pdf-customization-toggle")) return;

  const target = document.getElementById(event.target.dataset.target);
  if (!target) return;

  target.classList.toggle("d-none", !event.target.checked);

  const status = event.target.closest(".pdf-toggle-wrap")?.querySelector(".pdf-toggle-status");
  if (status) status.textContent = event.target.checked ? "Ativo" : "Inativo";

  const formData = new FormData();
  formData.append("company_pdf_setting[document_type]", event.target.dataset.documentType);
  formData.append("company_pdf_setting[customization_enabled]", event.target.checked ? "1" : "0");

  fetch(event.target.dataset.url, {
    method: "PATCH",
    headers: {
      "X-CSRF-Token": csrfToken(),
      "Accept": "application/json",
      "X-Requested-With": "XMLHttpRequest"
    },
    body: formData,
    credentials: "same-origin"
  }).catch(function() {
    window.location.href = redirectUrl();
  });
});

document.addEventListener("click", function(event) {
  const button = event.target.closest(".pdf-remove-logo-button");
  if (!button) return;

  event.preventDefault();
  if (!window.confirm("Remover a logo atual?")) return;

  fetch(button.dataset.url, {
    method: "DELETE",
    headers: {
      "X-CSRF-Token": csrfToken(),
      "Accept": "text/html"
    },
    credentials: "same-origin"
  }).then(function(response) {
    window.location.href = response.url || redirectUrl();
  }).catch(function() {
    window.location.href = redirectUrl();
  });
});
