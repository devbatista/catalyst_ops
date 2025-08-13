import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// 1. Crie a instância da aplicação Stimulus aqui mesmo
const application = Application.start()

// 2. Configure a aplicação
application.debug = false
window.Stimulus = application

// 3. Carregue os controladores
eagerLoadControllersFrom("controllers", application)