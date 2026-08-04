import { Controller } from "@hotwired/stimulus"

// Lets the "I can drive" / "I need a ride" buttons in a direction section
// select the matching role in that section's join form while the browser
// follows the anchor to it — no server round-trip.
export default class extends Controller {
  static targets = ["role"]

  pick(event) {
    this.roleTargets.forEach(radio => {
      radio.checked = radio.value === event.params.role
      if (radio.checked) radio.dispatchEvent(new Event("change", { bubbles: true }))
    })
  }
}
