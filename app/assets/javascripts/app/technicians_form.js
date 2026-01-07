import { formatPhone, onlyDigits } from "../utils/formatters";

document.addEventListener("DOMContentLoaded", function () {
  // Telefone
  document.querySelectorAll('input[data-mask="phone"]').forEach(input => {
    input.addEventListener("input", function () {
      const prev = input.value;
      input.value = formatPhone(prev);
      input.setSelectionRange(input.value.length, input.value.length);
    });
  });
});

document.addEventListener('click', async function (e) {
  const deleteLink = e.target.closest('a.js-delete-technician')
  if (!deleteLink) return

  e.preventDefault()

  const confirmMsg = deleteLink.dataset.confirm
  if (confirmMsg && !confirm(confirmMsg)) {
    return
  }

  const csrfToken = document
    .querySelector('meta[name="csrf-token"]')
    ?.getAttribute('content')

  try {
    const resp = await fetch(deleteLink.href, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': csrfToken || '',
        'Accept': 'text/html,application/xhtml+xml'
      },
      credentials: 'same-origin',
      redirect: 'follow'
    })

    if (resp.redirected) {
      window.location.href = resp.url
    } else {
      window.location.reload()
    }
  } catch (_err) {
    window.location.href = deleteLink.href
  }
})