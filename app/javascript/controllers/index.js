import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Carrega automaticamente todos os *_controller.js em app/javascript/controllers
eagerLoadControllersFrom("controllers", application)