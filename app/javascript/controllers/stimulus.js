import { Controller } from "@hotwired/stimulus"
import PerfectScrollbar from "perfect-scrollbar"

// ...existing code...
export default class extends Controller {
  connect() { this.ps = new PerfectScrollbar(this.element) }
  disconnect() { this.ps?.destroy(); this.ps = null }
}