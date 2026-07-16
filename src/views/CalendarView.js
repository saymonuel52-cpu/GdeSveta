const CalendarView = {
  currentDate: new Date(),
  
  render: function() {
    const container = document.getElementById('calendarView');
    if (!container) return;
    
    const year = this.currentDate.getFullYear();
    const month = this.currentDate.getMonth();
    const today = new Date();
    
    const monthNames = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
    const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    
    // Первый день месяца
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    
    // Смещение (понедельник = 0)
    let startDay = firstDay.getDay() - 1;
    if (startDay < 0) startDay = 6;
    
    let html = '<div style="padding:20px;">';
    
    // Навигация по месяцам
    html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">';
    html += '<button onclick="CalendarView.prevMonth()" style="padding:8px 16px;background:#f0f0f0;border:none;border-radius:8px;cursor:pointer;font-size:18px;">‹</button>';
    html += '<h3 style="margin:0;color:#1e293b;">' + monthNames[month] + ' ' + year + '</h3>';
    html += '<button onclick="CalendarView.nextMonth()" style="padding:8px 16px;background:#f0f0f0;border:none;border-radius:8px;cursor:pointer;font-size:18px;">›</button>';
    html += '</div>';
    
    // Сетка дней недели
    html += '<div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-bottom:10px;">';
    dayNames.forEach(day => {
      html += '<div style="text-align:center;font-size:12px;color:#94a3b8;font-weight:600;">' + day + '</div>';
    });
    html += '</div>';
    
    // Сетка дней
    html += '<div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;">';
    
    // Пустые ячейки до первого дня
    for (let i = 0; i < startDay; i++) {
      html += '<div></div>';
    }
    
    // Дни месяца
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day);
      const dateStr = date.toISOString().split('T')[0];
      const isToday = date.toDateString() === today.toDateString();
      
      // Проверяем есть ли записи на этот день
      const dayEntries = Store.getEntries().filter(e => e.date === dateStr);
      const hasEntries = dayEntries.length > 0;
      
      let style = 'text-align:center;padding:12px 8px;border-radius:12px;cursor:pointer;transition:all 0.2s;';
      
      if (isToday) {
        style += 'background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;font-weight:700;';
      } else if (hasEntries) {
        style += 'background:#fff0f3;color:#ff6b9d;font-weight:600;';
      } else {
        style += 'background:#f8fafc;color:#1e293b;';
      }
      
      html += '<div onclick="CalendarView.selectDate(\'' + dateStr + '\')" style="' + style + '">';
      html += day;
      if (hasEntries) {
        html += '<div style="font-size:10px;margin-top:4px;">' + dayEntries.length + ' зап.</div>';
      }
      html += '</div>';
    }
    
    html += '</div></div>';
    
    container.innerHTML = html;
    console.log('✅ CalendarView отрисован');
  },
  
  prevMonth: function() {
    this.currentDate.setMonth(this.currentDate.getMonth() - 1);
    this.render();
  },
  
  nextMonth: function() {
    this.currentDate.setMonth(this.currentDate.getMonth() + 1);
    this.render();
  },
  
  selectDate: function(dateStr) {
    console.log('📅 Выбрана дата:', dateStr);
    // Открываем форму добавления с выбранной датой
    if (typeof window.openWorkForm === 'function') {
      window.openWorkForm(null, dateStr);
    }
  }
};

window.CalendarView = CalendarView;
console.log('✅ CalendarView загружен');
