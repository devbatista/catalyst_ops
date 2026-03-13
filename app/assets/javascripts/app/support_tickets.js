document.addEventListener('click', async function (e) {
  const link = e.target.closest('a.js-close-ticket');
  if (!link) return;

  e.preventDefault();

  const confirmMsg = link.dataset.confirm;
  if (confirmMsg && !confirm(confirmMsg)) return;

  const csrfToken = document
    .querySelector('meta[name="csrf-token"]')
    ?.getAttribute('content');

  try {
    const resp = await fetch(link.href, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken || '',
        'Accept': 'application/json'
      },
      credentials: 'same-origin'
    });

    const data = await resp.json();

    if (data.success) {
      window.location.reload(); // ou atualize só o status na página
    } else {
      alert(data.errors.join("\n"));
    }
  } catch (_err) {
    alert("Erro ao fechar o ticket.");
  }
});