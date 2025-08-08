# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/ujs", to: "https://cdn.jsdelivr.net/npm/@rails/ujs@7.0.0/lib/assets/compiled/rails-ujs.js"
pin "perfect-scrollbar", to: "https://ga.jspm.io/npm:perfect-scrollbar@1.5.5/dist/perfect-scrollbar.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"
