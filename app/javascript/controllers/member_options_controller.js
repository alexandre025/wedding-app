import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ageGroup", "attendance", "options", "alcohol", "run"]
  static values = { adultGroup: String, childGroups: Array }

  connect() {
    this.applyAgeRules(false)
    this.toggleOptions()
  }

  refresh() {
    this.applyAgeRules(true)
    this.toggleOptions()
  }

  toggleOptions() {
    this.optionsTarget.hidden = this.attendanceTarget.value !== "true"
  }

  applyAgeRules(resetWhenEditable) {
    const ageGroup = this.ageGroupTarget.value

    this.apply(this.alcoholTarget, ageGroup !== this.adultGroupValue, true, resetWhenEditable)
    this.apply(this.runTarget, this.childGroupsValue.includes(ageGroup), false, resetWhenEditable)
  }

  apply(checkBox, locked, valueWhenLocked, resetWhenEditable) {
    const wasLocked = checkBox.disabled
    checkBox.disabled = locked

    if (locked) {
      checkBox.checked = valueWhenLocked
    } else if (resetWhenEditable && wasLocked) {
      checkBox.checked = false
    }
  }
}
