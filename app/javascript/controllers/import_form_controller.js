import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['modal']

  open() {
    this.modalTarget.classList.remove('hidden')
  }

  close() {
    this.modalTarget.classList.add('hidden')
  }

  handleSubmit(event) {
    const { fetchResponse } = event.detail
    if (fetchResponse && fetchResponse.response.ok) {
      this.close()
    }
  }
}
