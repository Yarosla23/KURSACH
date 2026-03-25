import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = { config: Object }

  connect() {
    if (!window.Chart) {
      console.warn("Chart.js is not available on window.Chart")
      return
    }

    this.chart = new window.Chart(this.canvasTarget, this.configValue)
  }

  disconnect() {
    this.chart?.destroy()
  }
}
