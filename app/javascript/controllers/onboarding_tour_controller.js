import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    endpoint: String,
    steps: Array,
    autoStart: Boolean
  }

  connect() {
    this.intro = null
    this.persistableStepKeys = []
    this.onWelcomeStarted = this.onWelcomeStarted.bind(this)
    window.addEventListener("onboarding-welcome:started", this.onWelcomeStarted)

    if (!this.autoStartValue) return

    this.startTour().catch((error) => {
      console.warn("[OnboardingTour] failed to start", error)
    })
  }

  disconnect() {
    window.removeEventListener("onboarding-welcome:started", this.onWelcomeStarted)

    if (!this.intro) return

    this.intro.exit()
    this.intro = null
  }

  onWelcomeStarted() {
    this.startTour().catch((error) => {
      console.warn("[OnboardingTour] failed to start from welcome", error)
    })
  }

  async startTour() {
    if (typeof window.introJs === "undefined") return

    await this.resumeIfRequested()

    const progress = await this.fetchProgress()
    this.persistableStepKeys = Array.isArray(progress?.step_keys) ? progress.step_keys : []
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

      const persistStepKey = targetElement?.dataset?.onboardingTourPersistStepKey || stepKey
      if (this.persistableStepKeys.includes(persistStepKey)) {
        this.persistLastSeen(persistStepKey)
      }
      this.enforceSkipButtonLayout()
    })

    this.intro.onafterchange(() => this.enforceSkipButtonLayout())
    this.intro.onexit(() => this.clearAutoStartParam())
    this.intro.oncomplete(() => this.clearAutoStartParam())

    const resumeIndex = this.findResumeIndex(progress?.last_seen_step, builtSteps)
    this.intro.start()
    this.enforceSkipButtonLayout()

    if (resumeIndex > 0) {
      this.intro.goToStep(resumeIndex + 1)
      this.enforceSkipButtonLayout()
    }
  }

  async resumeIfRequested() {
    const url = new URL(window.location.href)
    if (url.searchParams.get("resume_onboarding") !== "1") return

    await this.sendOperation("resume")
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
        if (step.persist_step_key) {
          element.dataset.onboardingTourPersistStepKey = step.persist_step_key
        }

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

    const idx = steps.findIndex((step) => {
      const visibleStepKey = step.element?.dataset?.onboardingTourStepKey
      const persistStepKey = step.element?.dataset?.onboardingTourPersistStepKey
      return visibleStepKey === lastSeenStep || persistStepKey === lastSeenStep
    })
    if (idx < 0) return 0

    return Math.min(idx + 1, Math.max(steps.length - 1, 0))
  }

  async persistLastSeen(stepKey) {
    await this.sendOperation("set_last_seen", stepKey)
  }

  async sendOperation(operation, stepKey = null) {
    if (!this.hasEndpointValue || !this.endpointValue) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    const body = { operation }
    if (stepKey) body.step_key = stepKey

    try {
      await fetch(this.endpointValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken || ""
        },
        credentials: "same-origin",
        body: JSON.stringify(body)
      })
    } catch (_error) {
      // noop
    }
  }

  clearAutoStartParam() {
    const url = new URL(window.location.href)
    url.searchParams.delete("onboarding_tour")
    url.searchParams.delete("resume_onboarding")
    window.history.replaceState({}, "", url.toString())
  }

  enforceSkipButtonLayout() {
    window.requestAnimationFrame(() => {
      const tooltip = document.querySelector(".introjs-tooltip")
      const skipButton = document.querySelector(".introjs-skipbutton")
      const title = document.querySelector(".introjs-tooltip .introjs-tooltip-title")

      if (!tooltip || !skipButton) return

      tooltip.style.position = "relative"
      skipButton.style.position = "absolute"
      skipButton.style.top = "10px"
      skipButton.style.right = "12px"
      skipButton.style.left = "auto"
      skipButton.style.width = "auto"
      skipButton.style.height = "auto"
      skipButton.style.lineHeight = "1.2"
      skipButton.style.padding = "4px 9px"
      skipButton.style.margin = "0"
      skipButton.style.display = "inline-block"
      skipButton.style.borderRadius = "999px"
      skipButton.style.textDecoration = "none"
      skipButton.style.zIndex = "20"

      if (title) title.style.paddingRight = "72px"
    })
  }
}
