import { Controller } from "@hotwired/stimulus"

// カード操作を管理するコントローラー
export default class extends Controller {
  // Snoozeボタンをクリックした時
  showSnoozeForm(event) {
    const cardId = event.currentTarget.dataset.cardId
    const form = document.getElementById(`snooze-form-${cardId}`)
    form.classList.remove('hidden')
  }

  // キャンセルボタンをクリックした時
  hideSnoozeForm(event) {
    const cardId = event.currentTarget.dataset.cardId
    const form = document.getElementById(`snooze-form-${cardId}`)
    form.classList.add('hidden')
  }
}
