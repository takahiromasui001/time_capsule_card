import { Controller } from "@hotwired/stimulus"

// カード作成フォームの開閉を管理するコントローラー
export default class extends Controller {
  static targets = ["modal"]

  open() {
    this.modalTarget.classList.remove('hidden')
  }

  close() {
    this.modalTarget.classList.add('hidden')
    // フォームコンテンツをクリア（次回open時に新しいフォームが表示される）
    const content = document.getElementById('card_form_content')
    if (content) {
      content.innerHTML = ''
    }
  }

  handleSubmit(event) {
    const { fetchResponse } = event.detail
    if (fetchResponse && fetchResponse.response.ok) {
      this.close()
      window.location.reload()
    }
  }
}
