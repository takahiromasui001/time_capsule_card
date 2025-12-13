import { Controller } from "@hotwired/stimulus"

// カード作成フォームの開閉を管理するコントローラー
export default class extends Controller {
  static targets = ["modal"]

  open() {
    this.modalTarget.classList.remove('hidden')
  }

  close() {
    this.modalTarget.classList.add('hidden')
    // フォームをリセット（前回の入力が残らないように）
    const form = this.modalTarget.querySelector('form')
    if (form) form.reset()
  }

  handleSubmit(event) {
    if (event.detail.success) {
      this.close()
    }
  }
}
