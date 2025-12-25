import { Controller } from "@hotwired/stimulus"

// カード作成フォームの開閉を管理するコントローラー
export default class extends Controller {
  static targets = ["modal"]

  open() {
    this.modalTarget.classList.remove('hidden')
  }

  close() {
    this.modalTarget.classList.add('hidden')
    // フォームと入力値をリセット
    const form = this.modalTarget.querySelector('form')
    if (form) form.reset()
    // バリデーションエラーメッセージを削除
    this.modalTarget.querySelectorAll('[data-field-error]').forEach(el => el.remove())
  }

  handleSubmit(event) {
    const { fetchResponse } = event.detail
    if (fetchResponse && fetchResponse.response.ok) {
      this.close()
      window.location.reload()
    }
  }
}
