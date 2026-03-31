import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar", "technicianFilter"]
  static TECHNICIAN_EVENT_COLORS = [
    "#0D6EFD",
    "#198754",
    "#FD7E14",
    "#6F42C1",
    "#D63384",
    "#20C997",
    "#DC3545",
    "#0DCAF0"
  ]

  connect() {
    if (typeof FullCalendar === "undefined") {
      console.error("Biblioteca FullCalendar não encontrada.");
      return;
    }

    this.techniciansLoaded = false;
    this.wrapperRevealed = false;
    this.selectedTechnicianIdsState = [];
    this.nativeTechnicianChangeBound = false;

    const calendarElement = this.hasCalendarTarget ? this.calendarTarget : this.element;

    this.calendar = new FullCalendar.Calendar(calendarElement, {
      locale: "pt-br",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,timeGridDay,listWeek"
      },
      initialView: "dayGridMonth",
      navLinks: true,
      selectable: true,
      nowIndicator: true,
      dayMaxEvents: true,
      editable: true,
      businessHours: true,
      loading: (isLoading) => {
        if (!isLoading) {
          if (!this.wrapperRevealed) {
            this.revealWrapper();
          }

          if (!this.techniciansLoaded) {
            this.loadTechnicians();
          }
        }
      },
      events: (fetchInfo, successCallback, failureCallback) =>
        this.fetchCalendarEvents(fetchInfo, successCallback, failureCallback)
    });

    this.calendar.render();
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy();
      if (this.hasCalendarTarget) {
        this.calendarTarget.innerHTML = "";
      } else {
        this.element.innerHTML = "";
      }
    }

    if (typeof window.$ !== "undefined" && this.hasTechnicianFilterTarget) {
      const $select = window.$(this.technicianFilterTarget);
      $select.off(".calendar");
      if ($select.data("select2")) {
        $select.select2("destroy");
      }
    }
  }

  reloadEvents() {
    this.syncSelectedTechnicianIds();
    if (this.calendar) {
      this.calendar.refetchEvents();
    }
  }

  revealWrapper() {
    this.element.classList.remove("invisible");
    this.wrapperRevealed = true;
    this.calendar.updateSize();
  }

  async loadTechnicians() {
    if (!this.hasTechnicianFilterTarget) return;

    const select = this.technicianFilterTarget;
    select.disabled = true;
    select.innerHTML = '<option value="">Carregando técnicos...</option>';

    try {
      const response = await fetch("/calendar/technicians", {
        headers: { Accept: "application/json" }
      });

      if (!response.ok) throw new Error(`HTTP ${response.status}`);

      const technicians = await response.json();
      select.innerHTML = "";

      technicians.forEach((technician) => {
        const option = document.createElement("option");
        option.value = String(technician.id);
        option.textContent = technician.name;
        select.appendChild(option);
      });

      if (technicians.length === 0) {
        const option = document.createElement("option");
        option.value = "";
        option.textContent = "Nenhum técnico disponível";
        option.disabled = true;
        select.appendChild(option);
      }

      this.initializeTechnicianSelect2(select);
      this.syncSelectedTechnicianIds();
      this.techniciansLoaded = true;
    } catch (error) {
      console.error("Erro ao carregar técnicos do calendário:", error);
      select.innerHTML = '<option value="">Falha ao carregar técnicos</option>';
    } finally {
      select.disabled = false;
    }
  }

  async fetchCalendarEvents(fetchInfo, successCallback, failureCallback) {
    const selectedIds = this.selectedTechnicianIdsState;

    const params = new URLSearchParams({
      start: fetchInfo.startStr,
      end: fetchInfo.endStr,
      technician_ids: selectedIds.join(",")
    });

    try {
      const response = await fetch(`/calendar/events?${params.toString()}`, {
        headers: { Accept: "application/json" }
      });

      if (!response.ok) throw new Error(`HTTP ${response.status}`);

      const sourceEvents = await response.json();
      const builtEvents = this.buildCalendarEvents(sourceEvents, selectedIds);
      successCallback(builtEvents);
    } catch (error) {
      console.error("Erro ao carregar eventos do calendário:", error);
      alert("Falha ao carregar os eventos do calendário.");
      failureCallback(error);
    }
  }

  buildCalendarEvents(sourceEvents, selectedIds = []) {
    if (selectedIds.length === 0) {
      return sourceEvents.map((event) => ({
        id: event.id,
        title: event.default_title,
        start: event.start,
        end: event.end,
        url: event.url
      }));
    }

    const selectedIdSet = new Set(selectedIds);
    const built = sourceEvents.flatMap((event) => {
      const technicians = Array.isArray(event.technicians) ? event.technicians : [];

      return technicians
        .filter((technician) => selectedIdSet.has(String(technician.id)))
        .map((technician) => {
          const color = this.technicianColor(technician.id);

          return {
            id: `${event.id}-${technician.id}`,
            title: event.base_title,
            start: event.start,
            end: event.end,
            url: event.url,
            backgroundColor: color,
            borderColor: color,
            textColor: "#FFFFFF"
          };
        });
    });
    return built;
  }

  technicianColor(technicianId) {
    const id = String(technicianId || "");
    let hash = 0;
    for (let i = 0; i < id.length; i += 1) {
      hash = ((hash << 5) - hash) + id.charCodeAt(i);
      hash |= 0;
    }
    const index = Math.abs(hash) % this.constructor.TECHNICIAN_EVENT_COLORS.length;
    return this.constructor.TECHNICIAN_EVENT_COLORS[index];
  }

  initializeTechnicianSelect2(select) {
    if (typeof window.$ === "undefined" || !window.$.fn || !window.$.fn.select2) {
      this.bindNativeFilterChange(select);
      return;
    }

    const $select = window.$(select);
    if ($select.data("select2")) {
      $select.select2("destroy");
    }

    $select.select2({
      theme: "bootstrap-5",
      placeholder: select.dataset.placeholder || "Escolha os técnicos",
      width: "100%",
      closeOnSelect: false
    });

    $select.off(".calendar");
    $select.on("change.calendar", () => this.reloadEvents());
  }

  syncSelectedTechnicianIds() {
    if (!this.hasTechnicianFilterTarget) {
      this.selectedTechnicianIdsState = [];
      return;
    }

    let values = [];
    if (typeof window.$ !== "undefined") {
      const $select = window.$(this.technicianFilterTarget);
      values = $select.val() || [];
    } else {
      values = Array.from(this.technicianFilterTarget.selectedOptions).map((option) => option.value);
    }

    this.selectedTechnicianIdsState = ([]).concat(values).map((value) => String(value)).filter(Boolean);
  }

  bindNativeFilterChange(select) {
    if (this.nativeTechnicianChangeBound) return;

    select.addEventListener("change", () => this.reloadEvents());
    this.nativeTechnicianChangeBound = true;
  }
}
