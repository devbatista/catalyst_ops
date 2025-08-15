import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (typeof FullCalendar === "undefined") {
      console.error("Biblioteca FullCalendar não encontrada.");
      return;
    }

    this.calendar = new FullCalendar.Calendar(this.element, {
      locale: 'pt-br',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek,timeGridDay,listWeek'
      },
      initialView: 'dayGridMonth',
      navLinks: true,
      selectable: true,
      nowIndicator: true,
      dayMaxEvents: true, // A opção que queremos que funcione
      editable: true,
      businessHours: true,
      events: {
        url: '/calendar/events',
        failure: () => {
          alert('Falha ao carregar os eventos do calendário.');
        }
      }
    });

    this.calendar.render();
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy();
      this.element.innerHTML = '';
    }
  }
}