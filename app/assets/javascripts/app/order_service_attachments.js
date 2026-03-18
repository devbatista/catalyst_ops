document.addEventListener('click', async function (e) {
  const deleteLink = e.target.closest('a.js-delete-attachment');
  if (!deleteLink) return;

  e.preventDefault();

  const confirmMsg = deleteLink.dataset.confirm;
  if (confirmMsg && !confirm(confirmMsg)) return;

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');

  try {
    const resp = await fetch(deleteLink.href, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': csrfToken || '',
        'Accept': 'text/html'
      },
      credentials: 'same-origin'
    });

    if (resp.ok) {
      // Recarrega só a lista de anexos via AJAX
      const orderServiceId = deleteLink.closest('ul').dataset.orderServiceId;
      const listResp = await fetch(`/order_services/${orderServiceId}/attachments`);
      const html = await listResp.text();
      document.getElementById('attachments-list').innerHTML = html;
    } else {
      window.location.reload();
    }
  } catch (_err) {
    window.location.reload();
  }
});