document.addEventListener('click', async function (e) {
  const link = e.target.closest('a.js-resolve-ticket');
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
        'Accept': 'text/html,application/xhtml+xml'
      },
      credentials: 'same-origin',
      redirect: 'follow'
    });

    if (resp.redirected) {
      window.location.href = resp.url;
    } else {
      window.location.reload();
    }
  } catch (_err) {
    window.location.href = link.href;
  }
});