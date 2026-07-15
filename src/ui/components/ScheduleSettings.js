/**
 * SCHEDULE SETTINGS UI
 * Интерфейс настройки рабочего времени
 */

const ScheduleSettings = {
  open: function() {
    const settings = ScheduleRules.getSettings();
    const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    
    const content = `
      <form id="scheduleForm" onsubmit="return ScheduleSettings.save(event)">
        <label>Рабочие дни</label>
        <div class="work-days-selector">
          ${[0,1,2,3,4,5,6].map(day => `
            <label class="day-checkbox">
              <input type="checkbox" name="workDays" value="${day}" 
                ${settings.workDays.includes(day) ? 'checked' : ''}>
              <span>${dayNames[day]}</span>
            </label>
          `).join('')}
        </div>
        
        <label>Начало рабочего дня</label>
        <input type="time" id="workStart" value="${settings.workStart}" required>
        
        <label>Конец рабочего дня</label>
        <input type="time" id="workEnd" value="${settings.workEnd}" required>
        
        <label class="checkbox-label">
          <input type="checkbox" id="lunchEnabled" 
            ${settings.lunchBreak.enabled ? 'checked' : ''}
            onchange="document.getElementById('lunchSettings').style.display = this.checked ? 'block' : 'none'">
          <span>Обеденный перерыв</span>
        </label>
        
        <div id="lunchSettings" style="display: ${settings.lunchBreak.enabled ? 'block' : 'none'}">
          <label>Начало обеда</label>
          <input type="time" id="lunchStart" value="${settings.lunchBreak.start}">
          
          <label>Конец обеда</label>
          <input type="time" id="lunchEnd" value="${settings.lunchBreak.end}">
        </div>
        
        <label>Буфер между записями (минут)</label>
        <input type="number" id="bufferTime" value="${settings.bufferTime}" min="0" max="60">
        
        <label>Максимум записей в день</label>
        <input type="number" id="maxBookings" value="${settings.maxBookingsPerDay}" min="1" max="20">
        
        <div class="form-actions">
          <button type="submit" class="save-btn">Сохранить</button>
          <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
        </div>
      </form>
    `;
    
    Modal.form({ title: '⚙️ Настройки рабочего времени', content });
  },

  save: function(e) {
    e.preventDefault();
    
    const workDays = Array.from(document.querySelectorAll('input[name="workDays"]:checked'))
      .map(cb => parseInt(cb.value));
    
    if (workDays.length === 0) {
      Modal.alert('❌ Выберите хотя бы один рабочий день!');
      return false;
    }
    
    const settings = {
      workDays,
      workStart: document.getElementById('workStart').value,
      workEnd: document.getElementById('workEnd').value,
      lunchBreak: {
        enabled: document.getElementById('lunchEnabled').checked,
        start: document.getElementById('lunchStart').value,
        end: document.getElementById('lunchEnd').value
      },
      bufferTime: parseInt(document.getElementById('bufferTime').value),
      maxBookingsPerDay: parseInt(document.getElementById('maxBookings').value)
    };
    
    ScheduleRules.saveSettings(settings);
    Modal.close();
    Modal.alert('✅ Настройки сохранены!');
    
    return false;
  }
};

window.ScheduleSettings = ScheduleSettings;
