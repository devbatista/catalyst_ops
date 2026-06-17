document.addEventListener('click', async function (e) {
  const deleteLink = e.target.closest('a.js-delete-coupon')
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
