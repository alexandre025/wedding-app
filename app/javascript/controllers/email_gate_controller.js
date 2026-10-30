import { Controller } from "@hotwired/stimulus"

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

// Drives the invitation email gate. Until there is a guest list to look an
// address up in, this only tells a malformed address from a well-formed one —
// the "unknown address" message in the template waits for that server lookup.
export default class extends Controller {
  static targets = ["form", "input", "invalidError", "panel", "email"]
  static classes = ["invalid"]

  submit(event) {
    event.preventDefault()

    const address = this.inputTarget.value.trim()
    this.inputTarget.value = address

    if (EMAIL_PATTERN.test(address)) {
      this.emailTarget.textContent = address
      this.formTarget.hidden = true
      this.panelTarget.hidden = false
    } else {
      this.invalidErrorTarget.hidden = false
      this.inputTarget.setAttribute("aria-invalid", "true")
      this.inputTarget.classList.add(...this.invalidClasses)
      this.inputTarget.focus()
    }
  }

  clear() {
    this.invalidErrorTarget.hidden = true
    this.inputTarget.removeAttribute("aria-invalid")
    this.inputTarget.classList.remove(...this.invalidClasses)
  }

  reset() {
    this.inputTarget.value = ""
    this.clear()
    this.panelTarget.hidden = true
    this.formTarget.hidden = false
    this.inputTarget.focus()
  }
}
