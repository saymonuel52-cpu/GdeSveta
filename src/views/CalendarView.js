/**
 * CALENDAR VIEW v2.0
 * Без attachEvents — используем inline onclick из EntryCard
 */

const CalendarView = {
  container: null,
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    const selectedDate = Calendar.getSelectedDate();
    const entries = EntryService.getByDate(selectedDate);
    const notes = NoteService.getByDate(selectedDate);
    
    let html = `
      <div id="calendarContainer"></div>
      <div class="legend">
        <span class="legend-item"><span class="legend-color work"></span>Работа</span>
        <span class="legend-item"><span class="legend-color family"></span>Семья</span>
        <span class="legend-item"><span class="legend-color note"></span>Заметки</span>
      </div>
      <h3 style="margin:15px 0 10px;">${Utils.formatDate(selectedDate, 'long')}</h3>
    `;
    
    // Заметки
    notes.forEach(note => {
      html += NoteCard.render(note);
    });
    
    // Записи
    if (entries.length === 0 && notes.length === 0) {
      html += '<div class="empty-state">Нет записей на этот день</div>';
    } else {
      entries.forEach(entry => {
        html += EntryCard.render(entry);
      });
    }
    
    this.container.innerHTML = html;
    
    // Инициализируем календарь
    Calendar.init('calendarContainer');
    
    // ЭТОТ МЕТОД УДАЛЕН — всё через inline onclick
  },
  
  setupListeners() {
    Events.on('date:selected', () => this.render());
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.CalendarView = CalendarView;
