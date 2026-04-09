document.addEventListener("click", function (event) {
  if (event.target.matches("#add-received-item")) {
    event.preventDefault();
    const container = document.getElementById("received-items-list");
    const templateNode = document.getElementById("received-item-template");
    if (!container || !templateNode) return;

    const template = templateNode.innerHTML;
    const newIndex = new Date().getTime();
    const newRow = template.replace(/NEW_INDEX/g, newIndex);
    container.insertAdjacentHTML("beforeend", newRow);
    return;
  }

  const removeButton = event.target.closest(".remove-received-item");
  if (!removeButton) return;

  event.preventDefault();
  const row = removeButton.closest(".received-item-row");
  if (!row) return;

  const destroyFlag = row.querySelector(".received-item-destroy-flag");
  if (destroyFlag) {
    destroyFlag.value = "1";
    row.style.display = "none";
  } else {
    row.remove();
  }
});
