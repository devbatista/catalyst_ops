import * as Rails from "@rails/ujs"
Rails.start()

import "@hotwired/turbo-rails"
import "./controllers"

import * as PerfectScrollbar from "perfect-scrollbar"
import * as jquery from "jquery"
import * as select2 from "select2"
import * as Chart from "chart.js/auto"
import "metismenu"
import "jquery-jvectormap"

// Exponha o jQuery globalmente para plugins que dependem dele
window.$ = jquery
window.jQuery = jquery

document.addEventListener("turbo:load", () => {
  const psElement = document.querySelector(".app-container")
  if (psElement) {
    try {
      psElement._ps && psElement._ps.destroy()
      psElement._ps = new PerfectScrollbar.default(psElement)
    } catch (e) {
      console.error("Erro ao inicializar PerfectScrollbar:", e)
    }
  }

  if (jquery && jquery('#multiple-select-field').length > 0) {
    try {
      jquery('#multiple-select-field').select2({
        theme: 'bootstrap-5',
        placeholder: jquery('#multiple-select-field').data('placeholder'),
        width: '100%'
      })
    } catch (e) {
      console.error("Erro ao inicializar Select2:", e)
    }
  }

  const canvas = document.getElementById("orders-chart")
  if (canvas && Chart) {
    try {
      if (canvas._chart) {
        canvas._chart.destroy()
      }
      const ctx = canvas.getContext("2d")
      canvas._chart = new Chart.Chart(ctx, { // note o uso de Chart.Chart no pacote UMD
        type: "bar",
        data: {
          labels: ["Jan", "Feb", "Mar", "Apr", "May"],
          datasets: [{
            label: "Vendas",
            data: [12, 19, 3, 5, 2],
            backgroundColor: "rgba(75, 192, 192, 0.5)"
          }]
        }
      })
    } catch (e) {
      console.error("Erro ao inicializar gráfico:", e)
    }
  }
})

document.addEventListener("turbo:before-cache", () => {
  if (jquery && jquery('#multiple-select-field').length > 0) {
    try {
      jquery('#multiple-select-field').select2('destroy')
    } catch {}
  }
})
