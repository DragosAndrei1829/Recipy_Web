import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "recipy_cookie_preferences"
const DEFAULT_PREFERENCES = {
  essential: true,
  preferences: false,
  analytics: false,
  marketing: false,
}

export default class extends Controller {
  static targets = ["banner", "dialog", "prefCheckbox"]
  static values = {
    preferences: String,
  }

  connect() {
    this.handleExternalOpen = () => this.openPreferences()
    window.addEventListener("cookie-consent:open", this.handleExternalOpen)

    this.preferences = this.loadPreferences()
    if (this.preferences) {
      this.populateForm(this.preferences)
      this.hideBanner()
    } else {
      this.showBanner()
    }
  }

  disconnect() {
    window.removeEventListener("cookie-consent:open", this.handleExternalOpen)
  }

  loadPreferences() {
    try {
      const stored =
        (window.localStorage && window.localStorage.getItem(STORAGE_KEY)) ||
        this.preferencesValue

      if (!stored) return null

      const parsed = JSON.parse(stored)
      return { ...DEFAULT_PREFERENCES, ...parsed }
    } catch (error) {
      console.warn("Cookie preferences could not be parsed", error)
      return null
    }
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden")
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("hidden")
    }
  }

  openPreferences(event) {
    event?.preventDefault()
    this.hideBanner()
    if (this.hasDialogTarget) {
      this.populateForm(this.preferences || DEFAULT_PREFERENCES)
      this.dialogTarget.classList.remove("hidden")
    }
  }

  closePreferences(event) {
    event?.preventDefault()
    if (this.hasDialogTarget) {
      this.dialogTarget.classList.add("hidden")
    }
  }

  acceptAll(event) {
    event?.preventDefault()
    const prefs = {
      essential: true,
      preferences: true,
      analytics: true,
      marketing: true,
    }
    this.savePreferences(prefs)
  }

  essentialOnly(event) {
    event?.preventDefault()
    const prefs = { ...DEFAULT_PREFERENCES }
    this.savePreferences(prefs)
  }

  saveCustom(event) {
    event?.preventDefault()
    const prefs = { ...DEFAULT_PREFERENCES }
    this.prefCheckboxTargets.forEach((checkbox) => {
      const category = checkbox.dataset.category
      if (category && category !== "essential") {
        prefs[category] = checkbox.checked
      }
    })
    this.savePreferences(prefs)
  }

  populateForm(preferences) {
    this.prefCheckboxTargets.forEach((checkbox) => {
      const category = checkbox.dataset.category
      if (category && preferences[category] !== undefined) {
        checkbox.checked = Boolean(preferences[category])
      }
    })
  }

  savePreferences(preferences) {
    try {
      const serialized = JSON.stringify(preferences)
      if (window.localStorage) {
        window.localStorage.setItem(STORAGE_KEY, serialized)
      }
      document.cookie = `cookie_preferences=${encodeURIComponent(
        serialized
      )};path=/;max-age=${60 * 60 * 24 * 365};SameSite=Lax`
    } catch (error) {
      console.warn("Unable to persist cookie preferences", error)
    }

    this.preferences = preferences
    this.hideBanner()
    this.closePreferences()
  }
}

