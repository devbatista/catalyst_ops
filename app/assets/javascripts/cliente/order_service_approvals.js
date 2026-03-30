document.addEventListener("DOMContentLoaded", function () {
  const showButton = document.getElementById("show-rejection-form");
  const hideButton = document.getElementById("hide-rejection-form");
  const formWrapper = document.getElementById("rejection-form-wrapper");
  const reasonField = document.getElementById("rejection_reason");

  if (!showButton || !formWrapper) return;

  showButton.addEventListener("click", function () {
    formWrapper.classList.remove("d-none");
    showButton.classList.add("d-none");
    if (reasonField) reasonField.focus();
  });

  if (hideButton) {
    hideButton.addEventListener("click", function () {
      formWrapper.classList.add("d-none");
      showButton.classList.remove("d-none");
    });
  }
});
