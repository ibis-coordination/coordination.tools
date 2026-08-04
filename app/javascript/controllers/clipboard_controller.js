import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label"]

  async copy() {
    try {
      await navigator.clipboard.writeText(window.location.href)
      this.labelTarget.textContent = "Copied"
      window.setTimeout(() => this.labelTarget.textContent = "Copy link", 1800)
    } catch {
      // Clipboard access can be denied (odd browsers, webviews); fall back
      // to showing the URL so it can be copied by hand.
      window.prompt("Copy this link:", window.location.href)
    }
  }
}
