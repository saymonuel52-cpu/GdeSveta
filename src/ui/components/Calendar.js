/**
 * CALENDAR COMPONENT
 * Компонент календаря
 */

const Calendar = {
  currentDate: new Date(),
  selectedDate: Utils.getToday(),
  container: null,
  
  /**
   * Инициализировать календарь
   */
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) {
      console.error('[Calendar] Контейнер не найден');
      return;
    }
    
    this.render();
    this.setupControls();
  },
  
  /**
   * Отрендерить календарь
   */
  render() {
    if (!this.container) return;
    
    const year = this.currentDate.getFullYear();
    const month = this.currentDate.getMonth();
    
    const monthNames = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
    
    let html = `
      <div class="calendar-controls">
        <button id="prevMonth">‹</button>
        <h2>${monthNames[month]} ${year}</h2>
        <button id="nextMonth">›</button>
        <button id="todayBtn" class="small-btn">Сегодня</button>
      </div>
      <div class="calendar-grid">
    `;
    
    // Дни недели
    const dayNames = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
    dayNames.forEach(day => {
      html += `<div class="day-header">${day}</div>`;
    });
    
    // Первый день месяца
    const firstDay = new Date(year, month, 1);
    const startOffset = (firstDay.getDay() + 6) % 7;
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const prevMonthDays = new Date(year, month, 0).getDate();
    
    const today = Utils.getToday();
    const entries = Store.getEntries();
    
    // Предыдущий месяц
    for (let i = startOffset - 1; i >= 0; i--) {
      html += `<div class="day-cell other-month">${prevMonthDays - i}</div>`;
    }
    
    // Текущий месяц
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
      const classes = ['day-cell'];
      
      if (dateStr === today) classes.push('today');
      if (dateStr === this.selectedDate) classes.push('selected');
      
      // Проверяем наличие записей
      const hasEntries = entries.some(e => e.date === dateStr && e.status !== 'cancelled');
      if (hasEntries) {
        const workEntries = entries.filter(e => e.date === dateStr && e.category === 'work' && e.status !== 'cancelled');
        const familyEntries = entries.filter(e => e.date === dateStr && e.category === 'family' && e.status !== 'cancelled');
        
        if (workEntries.length > 0) classes.push('has-work');
        if (familyEntries.length > 0) classes.push('has-family');
      }
      
      html += `<div class="${classes.join(' ')}" data-date="${dateStr}">${d}</div>`;
    }
    
    html += `</div>`;
    this.container.innerHTML = html;
    
    // Обработчики кликов по дням
    this.container.querySelectorAll('.day-cell[data-date]').forEach(cell => {
      cell.addEventListener('click', () => {
        this.selectedDate = cell.dataset.date;
        this.render();
        Events.emit('date:selected', this.selectedDate);
      });
    });
  },
  
  /**
   * Настроить кнопки управления
   */
  setupControls() {
    const prevBtn = document.getElementById('prevMonth');
    const nextBtn = document.getElementById('nextMonth');
    const todayBtn = document.getElementById('todayBtn');
    
    if (prevBtn) {
      prevBtn.addEventListener('click', () => {
        this.currentDate.setMonth(this.currentDate.getMonth() - 1);
        this.render();
      });
    }
    
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        this.currentDate.setMonth(this.currentDate.getMonth() + 1);
        this.render();
      });
    }
    
    if (todayBtn) {
      todayBtn.addEventListener('click', () => {
        this.currentDate = new Date();
        this.selectedDate = Utils.getToday();
        this.render();
        Events.emit('date:selected', this.selectedDate);
      });
    }
  },
  
  /**
   * Получить выбранную дату
   */
  getSelectedDate() {
    return this.selectedDate;
  },
  
  /**
   * Перейти к дате
   */
  goToDate(date) {
    this.selectedDate = date;
    this.currentDate = new Date(date);
    this.render();
  }
};

window.Calendar = Calendar;
