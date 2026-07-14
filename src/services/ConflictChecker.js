/**
 * CONFLICT CHECKER
 * Проверка конфликтов расписания
 */

const ConflictChecker = {
  /**
   * Проверить конфликт для одной записи
   */
  checkForEntry(entry, excludeId = null) {
    const dayEntries = Store.getEntries().filter(e => {
      if (e.id === excludeId) return false;
      if (e.date !== entry.date) return false;
      if (e.status === 'cancelled') return false;
      if (e.category !== 'work') return false;
      return true;
    });
    
    const entryStart = Utils.timeToMinutes(entry.time);
    const entryEnd = entryStart + entry.duration;
    
    return dayEntries.find(e => {
      const eStart = Utils.timeToMinutes(e.time);
      const eEnd = eStart + e.duration;
      
      return (entryStart < eEnd && entryEnd > eStart);
    });
  },
  
  /**
   * Проверить все конфликты за период
   */
  checkPeriod(startDate, endDate) {
    const entries = Store.getEntries()
      .filter(e => e.date >= startDate && e.date <= endDate && e.status !== 'cancelled' && e.category === 'work');
    
    const conflicts = [];
    
    for (let i = 0; i < entries.length; i++) {
      for (let j = i + 1; j < entries.length; j++) {
        if (this.entriesConflict(entries[i], entries[j])) {
          conflicts.push({
            entry1: entries[i],
            entry2: entries[j]
          });
        }
      }
    }
    
    return conflicts;
  },
  
  /**
   * Проверить конфликт между двумя записями
   */
  entriesConflict(entry1, entry2) {
    if (entry1.date !== entry2.date) return false;
    
    const start1 = Utils.timeToMinutes(entry1.time);
    const end1 = start1 + entry1.duration;
    
    const start2 = Utils.timeToMinutes(entry2.time);
    const end2 = start2 + entry2.duration;
    
    return (start1 < end2 && end1 > start2);
  },
  
  /**
   * Найти свободное время в день
   */
  findFreeSlots(date, duration = 60, workStart = '09:00', workEnd = '21:00') {
    const dayEntries = Store.getEntries()
      .filter(e => e.date === date && e.status !== 'cancelled' && e.category === 'work')
      .sort((a, b) => Utils.timeToMinutes(a.time) - Utils.timeToMinutes(b.time));
    
    const slots = [];
    const workStartMins = Utils.timeToMinutes(workStart);
    const workEndMins = Utils.timeToMinutes(workEnd);
    
    let currentTime = workStartMins;
    
    dayEntries.forEach(entry => {
      const entryStart = Utils.timeToMinutes(entry.time);
      const entryEnd = entryStart + entry.duration;
      
      if (currentTime + duration <= entryStart) {
        slots.push({
          start: Utils.minutesToTime(currentTime),
          end: Utils.minutesToTime(currentTime + duration)
        });
      }
      
      currentTime = Math.max(currentTime, entryEnd);
    });
    
    if (currentTime + duration <= workEndMins) {
      slots.push({
        start: Utils.minutesToTime(currentTime),
        end: Utils.minutesToTime(currentTime + duration)
      });
    }
    
    return slots;
  },
  
  /**
   * Проверить загруженность дня
   */
  getDayLoad(date) {
    const entries = Store.getEntries()
      .filter(e => e.date === date && e.status !== 'cancelled' && e.category === 'work');
    
    const totalMinutes = entries.reduce((sum, e) => sum + e.duration, 0);
    const workDayMinutes = 12 * 60; // 12 часов
    
    return {
      entries: entries.length,
      minutes: totalMinutes,
      percent: Math.round((totalMinutes / workDayMinutes) * 100)
    };
  }
};

window.ConflictChecker = ConflictChecker;
