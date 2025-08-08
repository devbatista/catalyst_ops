
import { Controller } from "@hotwired/stimulus"
import PerfectScrollbar from "perfect-scrollbar"

export default class extends Controller {
  connect() { this.ps = new PerfectScrollbar(this.element) }
  disconnect() { this.ps?.destroy(); this.ps = null }
}