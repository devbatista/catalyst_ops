# Pin npm packages by running ./bin/importmap

pin "application"
# pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
# pin "@rails/ujs", to: "rails-ujs"
pin "perfect-scrollbar", to: "https://ga.jspm.io/npm:perfect-scrollbar@1.5.5/dist/perfect-scrollbar.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/register", under: "register"

pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js"
pin "select2", to: "https://ga.jspm.io/npm:select2@4.1.0-rc.0/dist/js/select2.js" # Linha adicionada pelo comando

pin "metisMenu", to: "https://ga.jspm.io/npm:metismenu@3.0.7/dist/metisMenu.js"

pin "app/clients_form"
pin "app/technicians_form"
pin "app/profile_form"
pin "app/company_form"