// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"
import * as Rails from "@rails/ujs"
Rails.start()

document.addEventListener("turbo:load", () => {
  const psEl = document.querySelector(".js-perfect-scrollbar")
  if (psEl && window.PerfectScrollbar) new PerfectScrollbar(psEl)

  const canvas = document.getElementById("orders-chart")
  if (canvas) {
    const ctx = canvas.getContext("2d")
    // inicialização do gráfico aqui...
  }
})

document.addEventListener("turbo:before-cache", () => {
  // destruir instâncias se necessário
})