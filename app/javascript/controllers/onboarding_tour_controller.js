import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    endpoint: String,
    steps: Array,
    autoStart: Boolean
  }

  connect() {
    this.intro = null

    if (!this.autoStartValue) return

    this.startTour().catch((error) => {
      console.warn("[OnboardingTour] failed to start", error)
    })
  }

  disconnect() {
    if (!this.intro) return

    this.intro.exit()
    this.intro = null
  }

  async startTour() {
    if (typeof window.introJs === "undefined") return

    const progress = await this.fetchProgress()
    const builtSteps = this.buildSteps()
    if (builtSteps.length === 0) return

    this.intro = window.introJs()
    this.intro.setOptions({
      steps: builtSteps,
      showProgress: true,
      showBullets: false,
      exitOnOverlayClick: false,
      nextLabel: "Próximo",
      prevLabel: "Voltar",
      doneLabel: "Concluir",
      skipLabel: "Pular"
    })

    this.intro.onchange((targetElement) => {
      const stepKey = targetElement?.dataset?.onboardingTourStepKey
      if (!stepKey) return

      this.persistLastSeen(stepKey)
    })

    this.intro.onexit(() => this.clearAutoStartParam())
    this.intro.oncomplete(() => this.clearAutoStartParam())

    const resumeIndex = this.findResumeIndex(progress?.last_seen_step, builtSteps)
    this.intro.start()

    if (resumeIndex > 0) {
      this.intro.goToStep(resumeIndex + 1)
    }
  }

  async fetchProgress() {
    if (!this.hasEndpointValue || !this.endpointValue) return null

    try {
      const response = await fetch(this.endpointValue, {
        method: "GET",
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      })

      if (!response.ok) return null

      const payload = await response.json()
      return payload.onboarding_progress || null
    } catch (_error) {
      return null
    }
  }

  buildSteps() {
    const configured = Array.isArray(this.stepsValue) ? this.stepsValue : []

    return configured
      .map((step) => {
        const element = document.querySelector(step.selector)
        if (!element) return null

        element.dataset.onboardingTourStepKey = step.key

        return {
          element,
          title: step.title,
          intro: step.description,
          tooltipClass: "introjs-tooltip-onboarding"
        }
      })
      .filter(Boolean)
  }

  findResumeIndex(lastSeenStep, steps) {
    if (!lastSeenStep) return 0

    const idx = steps.findIndex((step) => step.element?.dataset?.onboardingTourStepKey === lastSeenStep)
    if (idx < 0) return 0

    return Math.min(idx + 1, Math.max(steps.length - 1, 0))
  }

  async persistLastSeen(stepKey) {
    if (!this.hasEndpointValue || !this.endpointValue || !stepKey) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

    try {
      await fetch(this.endpointValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken || ""
        },
        credentials: "same-origin",
        body: JSON.stringify({ operation: "set_last_seen", step_key: stepKey })
      })
    } catch (_error) {
      // noop
    }
  }

  clearAutoStartParam() {
    const url = new URL(window.location.href)
    url.searchParams.delete("onboarding_tour")
    window.history.replaceState({}, "", url.toString())
  }
}
