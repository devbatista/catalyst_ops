document.addEventListener('click', function (e) {
  const deleteButton = e.target.closest('.js-mark-remove-attachment');
  if (!deleteButton) return;

  e.preventDefault();

  const confirmMsg = deleteButton.dataset.confirm;
  if (confirmMsg && !confirm(confirmMsg)) return;

  const attachmentId = deleteButton.dataset.attachmentId;
  if (!attachmentId) return;

  const form = deleteButton.closest('form');
  const hiddenContainer = form?.querySelector('#remove-attachment-inputs');
  if (!hiddenContainer) return;

  const alreadyMarked = hiddenContainer.querySelector(
    `input[name="order_service[remove_attachment_ids][]"][value="${attachmentId}"]`
  );

  if (!alreadyMarked) {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'order_service[remove_attachment_ids][]';
    input.value = attachmentId;
    hiddenContainer.appendChild(input);
  }

  const item = deleteButton.closest('li');
  if (item) item.remove();
});
