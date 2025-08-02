document.addEventListener('DOMContentLoaded', function () {
  var calendarEl = document.getElementById('calendar');
  var calendar = new FullCalendar.Calendar(calendarEl, {
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
    dayMaxEvents: true,
    editable: true,
    businessHours: true,
    // Aqui faz a requisição AJAX:
    events: '/calendar/events' // ajuste a rota conforme seu namespace
  });
  calendar.render();
});