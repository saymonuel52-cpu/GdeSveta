/**
 * SCHEDULE RULES
 * Управление рабочим временем и правилами расписания
 */

const ScheduleRules = {
  // Значения по умолчанию
  defaults: {
    workDays: [1, 2, 3, 4, 5, 6], // Пн-Сб (0=Вс, 1=Пн, ..., 6=Сб)
    workStart: '09:00',
    workEnd: '20:00',
    lunchBreak: { start: '13:00', end: '14:00', enabled: false },
    bufferTime: 10, // минут между записями
    maxBookingsPerDay: 8
  },

  // Получить текущие настройки
  getSettings: function() {
    const saved = Storage.get('scheduleRules', null);
    return saved ? JSON.parse(saved) : this.defaults;
  },

  // Сохранить настройки
  saveSettings: function(settings) {
    Storage.set('scheduleRules', JSON.stringify(settings));
  },

  // Проверить, является ли день рабочим
  isWorkDay: function(date) {
    const settings = this.getSettings();
    const dayOfWeek = new Date(date).getDay();
    return settings.workDays.includes(dayOfWeek);
  },

  // Проверить, находится ли время в рабочих часах
  isWorkTime: function(time) {
    const settings = this.getSettings();
    const [hours, minutes] = time.split(':').map(Number);
    const timeInMinutes = hours * 60 + minutes;
    
    const [startHours, startMinutes] = settings.workStart.split(':').map(Number);
    const [endHours, endMinutes] = settings.workEnd.split(':').map(Number);
    
    const startInMinutes = startHours * 60 + startMinutes;
    const endInMinutes = endHours * 60 + endMinutes;
    
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  },

  // Проверить обеденный перерыв
  isLunchBreak: function(time) {
    const settings = this.getSettings();
    if (!settings.lunchBreak.enabled) return false;
    
    const [hours, minutes] = time.split(':').map(Number);
    const timeInMinutes = hours * 60 + minutes;
    
    const [startHours, startMinutes] = settings.lunchBreak.start.split(':').map(Number);
    const [endHours, endMinutes] = settings.lunchBreak.end.split(':').map(Number);
    
    const startInMinutes = startHours * 60 + startMinutes;
    const endInMinutes = endHours * 60 + endMinutes;
    
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  },

  // Полная проверка времени записи
  validateBooking: function(date, time, duration) {
    const errors = [];
    const warnings = [];
    
    // Проверка рабочего дня
    if (!this.isWorkDay(date)) {
      errors.push('❌ Этот день — выходной');
    }
    
    // Проверка рабочего времени
    if (!this.isWorkTime(time)) {
      errors.push(' Время вне рабочих часов');
    }
    
    // Проверка обеденного перерыва
    if (this.isLunchBreak(time)) {
      errors.push('❌ Время обеда');
    }
    
    // Проверка окончания записи
    const [hours, minutes] = time.split(':').map(Number);
    const endTimeInMinutes = hours * 60 + minutes + duration;
    const settings = this.getSettings();
    const [endHours, endMinutes] = settings.workEnd.split(':').map(Number);
    const workEndInMinutes = endHours * 60 + endMinutes;
    
    if (endTimeInMinutes > workEndInMinutes) {
      errors.push('❌ Запись выходит за рабочее время');
    }
    
    // Проверка количества записей в день
    const dayEntries = Store.getEntries().filter(e => e.date === date && e.category === 'work');
    if (dayEntries.length >= settings.maxBookingsPerDay) {
      warnings.push('⚠️ Максимальное количество записей на этот день');
    }
    
    return { valid: errors.length === 0, errors, warnings };
  },

  // Найти свободные окна на дату
  findFreeSlots: function(date, duration) {
    const settings = this.getSettings();
    if (!this.isWorkDay(date)) return [];
    
    const entries = Store.getEntries()
      .filter(e => e.date === date && e.category === 'work')
      .sort((a, b) => a.time.localeCompare(b.time));
    
    const [startHours, startMinutes] = settings.workStart.split(':').map(Number);
    const [endHours, endMinutes] = settings.workEnd.split(':').map(Number);
    
    const dayStart = startHours * 60 + startMinutes;
    const dayEnd = endHours * 60 + endMinutes;
    
    const lunchStart = settings.lunchBreak.enabled ? 
      (parseInt(settings.lunchBreak.start.split(':')[0]) * 60 + parseInt(settings.lunchBreak.start.split(':')[1])) : null;
    const lunchEnd = settings.lunchBreak.enabled ? 
      (parseInt(settings.lunchBreak.end.split(':')[0]) * 60 + parseInt(settings.lunchBreak.end.split(':')[1])) : null;
    
    const slots = [];
    let currentTime = dayStart;
    
    for (const entry of entries) {
      const [entryHours, entryMinutes] = entry.time.split(':').map(Number);
      const entryStart = entryHours * 60 + entryMinutes;
      const entryEnd = entryStart + entry.duration + settings.bufferTime;
      
      // Проверяем окно перед записью
      if (currentTime + duration <= entryStart) {
        // Проверяем обед
        if (!(lunchStart && currentTime < lunchEnd && entryStart > lunchStart)) {
          slots.push({
            start: this.minutesToTime(currentTime),
            end: this.minutesToTime(currentTime + duration)
          });
        }
      }
      
      currentTime = Math.max(currentTime, entryEnd);
    }
    
    // Последнее окно дня
    if (currentTime + duration <= dayEnd) {
      if (!(lunchStart && currentTime < lunchEnd && dayEnd > lunchStart)) {
        slots.push({
          start: this.minutesToTime(currentTime),
          end: this.minutesToTime(currentTime + duration)
        });
      }
    }
    
    return slots;
  },

  minutesToTime: function(minutes) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
  }
};

window.ScheduleRules = ScheduleRules;
