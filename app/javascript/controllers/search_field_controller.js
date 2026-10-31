import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "clear"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.toggleClear()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  search() {
    this.toggleClear()
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  clear() {
    clearTimeout(this.timeout)
    this.fieldTarget.value = ""
    this.toggleClear()
    this.element.requestSubmit()
    this.fieldTarget.focus()
  }

  toggleClear() {
    this.clearTarget.hidden = this.fieldTarget.value.trim() === ""
  }
}
