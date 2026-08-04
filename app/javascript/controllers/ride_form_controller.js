import { Controller } from "@hotwired/stimulus"

// Keeps labels whose meaning depends on the selected role ("Seats you can
// offer" vs "Seats you need") in sync when the role radios change.
export default class extends Controller {
  static targets = ["role", "seatsLabel"]

  sync() {
    const role = this.roleTargets.find(radio => radio.checked)?.value || "driver"
    this.seatsLabelTargets.forEach(label => {
      label.textContent = role === "driver" ? label.dataset.driverText : label.dataset.riderText
    })
  }
}
