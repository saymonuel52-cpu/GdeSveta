const CalendarView = {
  render: function() {
    const container = document.getElementById('calendarView');
    if (!container) {
      console.error('❌ calendarView не найден');
      return;
    }
    
    const today = new Date();
    const monthNames = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
    
    let html = '<div style="padding:20px;">';
    html += '<h3 style="text-align:center;margin-bottom:20px;color:#1e293b;">';
    html += monthNames[today.getMonth()] + ' ' + today.getFullYear();
    html += '</h3>';
    
    html += '<div style="background:white;padding:30px;border-radius:16px;box-shadow:0 2px 12px rgba(0,0,0,0.08);">';
    html += '<p style="text-align:center;font-size:18px;color:#64748b;margin:0;">';
    html += '📅 ' + today.getDate() + ' ' + monthNames[today.getMonth()] + ' ' + today.getFullYear();
    html += '</p>';
    html += '<p style="text-align:center;margin-top:20px;color:#94a3b8;font-size:14px;">';
    html += 'Календарь работает';
    html += '</p>';
    html += '</div></div>';
    
    container.innerHTML = html;
    console.log('✅ CalendarView отрисован');
  }
};

window.CalendarView = CalendarView;
console.log('✅ CalendarView загружен');
