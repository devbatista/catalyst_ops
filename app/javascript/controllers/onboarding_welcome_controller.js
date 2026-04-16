import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "startButton", "dismissButton"]
  static values = {
    autoShow: Boolean,
    startPath: String
  }

  connect() {
    this.modalInstance = null
    this.fallbackBackdrop = null

    if (!this.hasModalTarget) return

    if (typeof window.bootstrap !== "undefined") {
      this.modalInstance = new window.bootstrap.Modal(this.modalTarget)

      if (this.autoShowValue) {
        this.modalInstance.show()
      }
      return
    }

    if (this.autoShowValue) {
      this.showFallback()
    }
  }

  disconnect() {
    if (this.modalInstance) {
      this.modalInstance.hide()
      this.modalInstance.dispose()
      this.modalInstance = null
      return
    }

    this.hideFallback()
  }

  async start() {
    this.setButtonsDisabled(true)

    await this.sendOperation("resume")
    this.hideModal()

    this.dispatch("started")

    if (this.hasStartPathValue && this.startPathValue) {
      window.location.href = this.startPathValue
      return
    }

    this.setButtonsDisabled(false)
  }

  async dismiss() {
    this.setButtonsDisabled(true)

    await this.sendOperation("dismiss")
    this.hideModal()
    this.setButtonsDisabled(false)
  }

  hideModal() {
    if (this.modalInstance) {
      this.modalInstance.hide()
      return
    }

    this.hideFallback()
  }

  async sendOperation(operation) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

    try {
      await fetch("/onboarding_progress", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken || ""
        },
        credentials: "same-origin",
        body: JSON.stringify({ operation })
      })
    } catch (error) {
      console.warn("Falha ao atualizar onboarding:", error)
    }
  }

  setButtonsDisabled(disabled) {
    if (this.hasStartButtonTarget) this.startButtonTarget.disabled = disabled
    if (this.hasDismissButtonTarget) this.dismissButtonTarget.disabled = disabled
  }

  showFallback() {
    this.modalTarget.classList.add("show")
    this.modalTarget.style.display = "block"
    this.modalTarget.removeAttribute("aria-hidden")
    this.modalTarget.setAttribute("aria-modal", "true")
    this.modalTarget.setAttribute("role", "dialog")
    document.body.classList.add("modal-open")

    this.fallbackBackdrop = document.createElement("div")
    this.fallbackBackdrop.className = "modal-backdrop fade show"
    document.body.appendChild(this.fallbackBackdrop)
  }

  hideFallback() {
    this.modalTarget.classList.remove("show")
    this.modalTarget.style.display = "none"
    this.modalTarget.setAttribute("aria-hidden", "true")
    this.modalTarget.removeAttribute("aria-modal")
    document.body.classList.remove("modal-open")

    if (this.fallbackBackdrop) {
      this.fallbackBackdrop.remove()
      this.fallbackBackdrop = null
    }
  }
}
