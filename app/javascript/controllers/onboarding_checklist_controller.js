import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "progressBar",
    "progressLabel",
    "titleLabel",
    "stepsList",
    "summary",
    "details",
    "toggleButton",
    "errorBox"
  ]

  static values = {
    endpoint: String,
    steps: Array,
    refreshMs: { type: Number, default: 20000 }
  }

  connect() {
    this.detailsExpanded = false
    this.refresh()
    this.startAutoRefresh()
    this.boundVisibilityHandler = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.boundVisibilityHandler)
  }

  disconnect() {
    this.stopAutoRefresh()
    if (this.boundVisibilityHandler) {
      document.removeEventListener("visibilitychange", this.boundVisibilityHandler)
    }
  }

  async refresh() {
    if (!this.hasEndpointValue || !this.endpointValue) return

    try {
      const response = await fetch(this.endpointValue, {
        method: "GET",
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const payload = await response.json()
      this.renderPayload(payload.onboarding_progress || {})
      this.hideError()
    } catch (error) {
      this.showError("Não foi possível carregar o checklist de onboarding agora.")
      console.warn("[OnboardingChecklist] refresh error", error)
    }
  }

  toggleDetails() {
    this.detailsExpanded = !this.detailsExpanded
    this.applyDetailsVisibility()
  }

  handleVisibilityChange() {
    if (!document.hidden) {
      this.refresh()
    }
  }

  startAutoRefresh() {
    this.stopAutoRefresh()
    this.refreshInterval = window.setInterval(() => this.refresh(), this.refreshMsValue)
  }

  stopAutoRefresh() {
    if (!this.refreshInterval) return
    window.clearInterval(this.refreshInterval)
    this.refreshInterval = null
  }

  renderPayload(data) {
    const completedSteps = data.completed_steps || {}
    const completedCount = Number(data.completed_steps_count || 0)
    const stepsTotal = Number(data.steps_total || this.stepsValue.length || 0)
    const progress = Number(data.progress_percentage || 0)
    const finished = data.finished === true

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${progress}%`
      this.progressBarTarget.setAttribute("aria-valuenow", String(progress))
    }

    if (this.hasProgressLabelTarget) {
      this.progressLabelTarget.textContent = `${completedCount}/${stepsTotal}`
    }

    if (this.hasTitleLabelTarget) {
      this.titleLabelTarget.textContent = finished ? "Onboarding concluído" : "Primeiros passos"
    }

    this.renderSteps(completedSteps)

    if (finished) {
      this.detailsExpanded = false
      this.summaryTarget.classList.remove("d-none")
    } else {
      this.summaryTarget.classList.add("d-none")
    }

    this.applyDetailsVisibility()
  }

  renderSteps(completedSteps) {
    if (!this.hasStepsListTarget) return

    const html = this.stepsValue.map((step) => {
      const done = completedSteps[step.key] === true
      const statusBadge = done
        ? '<span class="badge bg-success">Concluído</span>'
        : '<span class="badge bg-light text-dark border">Pendente</span>'

      const action = done
        ? ""
        : `<a class=\"btn btn-sm btn-outline-primary\" href=\"${step.path}\">Ir agora</a>`

      return `
        <li class="list-group-item d-flex align-items-center justify-content-between gap-3">
          <div class="d-flex align-items-center gap-2">
            <i class="bx ${done ? "bx-check-circle text-success" : "bx-circle text-secondary"}"></i>
            <span>${step.label}</span>
          </div>
          <div class="d-flex align-items-center gap-2">
            ${statusBadge}
            ${action}
          </div>
        </li>
      `
    }).join("")

    this.stepsListTarget.innerHTML = html
  }

  applyDetailsVisibility() {
    if (!this.hasDetailsTarget) return

    if (this.detailsExpanded) {
      this.detailsTarget.classList.remove("d-none")
      if (this.hasToggleButtonTarget) this.toggleButtonTarget.textContent = "Ocultar"
    } else {
      this.detailsTarget.classList.add("d-none")
      if (this.hasToggleButtonTarget) this.toggleButtonTarget.textContent = "Ver checklist"
    }
  }

  showError(message) {
    if (!this.hasErrorBoxTarget) return

    this.errorBoxTarget.textContent = message
    this.errorBoxTarget.classList.remove("d-none")
  }

  hideError() {
    if (!this.hasErrorBoxTarget) return

    this.errorBoxTarget.classList.add("d-none")
  }
}
