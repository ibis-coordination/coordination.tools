import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label"]

  async copy() {
    await navigator.clipboard.writeText(window.location.href)
    this.labelTarget.textContent = "Copied"
    window.setTimeout(() => this.labelTarget.textContent = "Copy link", 1800)
  }
}
