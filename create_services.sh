#!/bin/bash
echo " Создаю сервисы (бизнес-логика)..."

mkdir -p src/services

# 1. EntryService
cat > src/services/EntryService.js << 'ENTRY'
/**
 * ENTRY SERVICE
 * Бизнес-логика для работы с записями
 */

const EntryService = {
  /**
   * Получить все записи
   */
  getAll() {
    return Store.getEntries();
  },
  
  /**
   * Получить записи по дате
   */
  getByDate(date) {
    return Store.getEntries().filter(e => e.date === date && e.status !== 'cancelled');
  },
  
  /**
   * Получить записи по категории
   */
  getByCategory(category) {
    return Store.getEntries().filter(e => e.category === category && e.status !== 'cancelled');
  },
  
  /**
   * Получить записи за период
   */
  getByPeriod(startDate, endDate) {
    return Store.getEntries().filter(e => {
      return e.date >= startDate && e.date <= endDate && e.status !== 'cancelled';
    });
  },
  
  /**
   * Создать запись
   */
  create(data) {
    const entry = Entry.create(data);
    const validation = Entry.validate(entry);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    // Проверка конфликтов для рабочих записей
    if (entry.category === 'work') {
      const conflict = this.checkConflict(entry);
      if (conflict) {
        throw new Error(`Конфликт с записью: ${conflict.name}`);
      }
    }
    
    Store.addEntry(entry);
    Events.emit('entry:created', entry);
    return entry;
  },
  
  /**
   * Обновить запись
   */
  update(id, updates) {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) throw new Error('Запись не найдена');
    
    const updated = { ...entry, ...updates, updatedAt: new Date().toISOString() };
    const validation = Entry.validate(updated);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.updateEntry(id, updated);
    Events.emit('entry:updated', updated);
    return updated;
  },
  
  /**
   * Удалить запись
   */
  delete(id) {
    Store.deleteEntry(id);
    Events.emit('entry:deleted', id);
  },
  
  /**
   * Изменить статус
   */
  changeStatus(id, status) {
    return this.update(id, { status });
  },
  
  /**
   * Проверка конфликтов
   */
  checkConflict(entry) {
    const dayEntries = this.getByDate(entry.date);
    
    const entryStart = Utils.timeToMinutes(entry.time);
    const entryEnd = entryStart + entry.duration;
    
    return dayEntries.find(e => {
      if (e.id === entry.id) return false;
      
      const eStart = Utils.timeToMinutes(e.time);
      const eEnd = eStart + e.duration;
      
      return (entryStart < eEnd && entryEnd > eStart);
    });
  },
  
  /**
   * Получить статистику по записям
   */
  getStats(startDate, endDate) {
    const entries = this.getByPeriod(startDate, endDate);
    const workEntries = entries.filter(e => e.category === 'work');
    
    return {
      total: entries.length,
      work: workEntries.length,
      family: entries.filter(e => e.category === 'family').length,
      done: entries.filter(e => e.status === 'done').length,
      cancelled: entries.filter(e => e.status === 'cancelled').length,
      income: workEntries.reduce((sum, e) => sum + e.price, 0)
    };
  },
  
  /**
   * Дублировать запись
   */
  duplicate(id, newDate) {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) throw new Error('Запись не найдена');
    
    const duplicate = Entry.create({
      ...entry,
      date: newDate || entry.date,
      name: entry.name + ' (копия)',
      status: 'new'
    });
    
    Store.addEntry(duplicate);
    return duplicate;
  },
  
  /**
   * Получить ближайшие записи
   */
  getUpcoming(limit = 5) {
    const today = Utils.getToday();
    return this.getAll()
      .filter(e => e.date >= today && e.status !== 'cancelled')
      .sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time))
      .slice(0, limit);
  }
};

window.EntryService = EntryService;
ENTRY

echo "✅ services/EntryService.js создан"

# 2. NoteService
cat > src/services/NoteService.js << 'NOTE'
/**
 * NOTE SERVICE
 * Бизнес-логика для работы с заметками
 */

const NoteService = {
  getAll() {
    return Store.getNotes();
  },
  
  getByCategory(category) {
    return Store.getNotes().filter(n => n.category === category);
  },
  
  getByDate(date) {
    return Store.getNotes().filter(n => n.date === date);
  },
  
  create(data) {
    const note = Note.create(data);
    const validation = Note.validate(note);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.addNote(note);
    Events.emit('note:created', note);
    return note;
  },
  
  update(id, updates) {
    const note = Store.getNotes().find(n => n.id === id);
    if (!note) throw new Error('Заметка не найдена');
    
    const updated = { ...note, ...updates, updatedAt: new Date().toISOString() };
    Store.updateNote(id, updated);
    Events.emit('note:updated', updated);
    return updated;
  },
  
  delete(id) {
    Store.deleteNote(id);
    Events.emit('note:deleted', id);
  },
  
  toggleComplete(id) {
    const note = Store.getNotes().find(n => n.id === id);
    if (!note) throw new Error('Заметка не найдена');
    
    return this.update(id, { completed: !note.completed });
  },
  
  getShoppingList() {
    return this.getByCategory('shopping').filter(n => !n.completed);
  },
  
  getImportant() {
    return this.getByCategory('important');
  }
};

window.NoteService = NoteService;
NOTE

echo "✅ services/NoteService.js создан"

# 3. PriceService
cat > src/services/PriceService.js << 'PRICE'
/**
 * PRICE SERVICE
 * Бизнес-логика для управления прайсом
 */

const PriceService = {
  getAll() {
    return Store.getPriceList();
  },
  
  getActive() {
    return Store.getPriceList().filter(item => item.active);
  },
  
  getById(id) {
    return Store.getPriceList().find(item => item.id === id);
  },
  
  getByService(serviceType) {
    return Store.getPriceList().filter(item => item.service === serviceType && item.active);
  },
  
  create(data) {
    const item = PriceItem.create(data);
    const validation = PriceItem.validate(item);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.addPriceItem(item);
    Events.emit('price:created', item);
    return item;
  },
  
  update(id, updates) {
    const item = this.getById(id);
    if (!item) throw new Error('Услуга не найдена');
    
    const updated = { ...item, ...updates, updatedAt: new Date().toISOString() };
    const validation = PriceItem.validate(updated);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    const items = Store.getPriceList();
    const index = items.findIndex(i => i.id === id);
    items[index] = updated;
    Storage.set('gdesveta_store', { ...Storage.get('gdesveta_store'), priceList: items });
    
    Events.emit('price:updated', updated);
    return updated;
  },
  
  delete(id) {
    Store.deletePriceItem(id);
    Events.emit('price:deleted', id);
  },
  
  toggleActive(id) {
    const item = this.getById(id);
    if (!item) throw new Error('Услуга не найдена');
    
    return this.update(id, { active: !item.active });
  },
  
  getTotalIncome(entries) {
    return entries.reduce((sum, entry) => sum + (entry.price || 0), 0);
  },
  
  getPopularServices(limit = 5) {
    const entries = Store.getEntries().filter(e => e.category === 'work' && e.status !== 'cancelled');
    const serviceCount = {};
    
    entries.forEach(entry => {
      serviceCount[entry.service] = (serviceCount[entry.service] || 0) + 1;
    });
    
    return Object.entries(serviceCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([service, count]) => ({ service, count }));
  }
};

window.PriceService = PriceService;
PRICE

echo "✅ services/PriceService.js создан"

# 4. FamilyService
cat > src/services/FamilyService.js << 'FAMILY'
/**
 * FAMILY SERVICE
 * Бизнес-логика для управления семьёй
 */

const FamilyService = {
  getAll() {
    return Store.getFamilyMembers();
  },
  
  getById(id) {
    return Store.getFamilyMembers().find(m => m.id === id);
  },
  
  getChildren() {
    return Store.getFamilyMembers().filter(m => m.role === 'child' && m.active);
  },
  
  getAdults() {
    return Store.getFamilyMembers().filter(m => m.role === 'adult' && m.active);
  },
  
  getDogs() {
    return Store.getFamilyMembers().filter(m => m.role === 'dog' && m.active);
  },
  
  create(data) {
    const member = FamilyMember.create(data);
    const validation = FamilyMember.validate(member);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.addFamilyMember(member);
    Events.emit('family:created', member);
    return member;
  },
  
  update(id, updates) {
    const member = this.getById(id);
    if (!member) throw new Error('Член семьи не найден');
    
    const updated = { ...member, ...updates, updatedAt: new Date().toISOString() };
    const validation = FamilyMember.validate(updated);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    const members = Store.getFamilyMembers();
    const index = members.findIndex(m => m.id === id);
    members[index] = updated;
    Storage.set('gdesveta_store', { ...Storage.get('gdesveta_store'), familyMembers: members });
    
    Events.emit('family:updated', updated);
    return updated;
  },
  
  delete(id) {
    Store.deleteFamilyMember(id);
    Events.emit('family:deleted', id);
  },
  
  getCirclesForMember(memberId) {
    const member = this.getById(memberId);
    return member ? member.circles : [];
  },
  
  getScheduleForMember(memberId, date) {
    const entries = EntryService.getByDate(date);
    return entries.filter(e => e.familyMemberId === memberId);
  },
  
  getNextEventForMember(memberId) {
    const today = Utils.getToday();
    const entries = EntryService.getAll()
      .filter(e => e.familyMemberId === memberId && e.date >= today && e.status !== 'cancelled')
      .sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    
    return entries[0] || null;
  }
};

window.FamilyService = FamilyService;
FAMILY

echo "✅ services/FamilyService.js создан"

# 5. ConflictChecker
cat > src/services/ConflictChecker.js << 'CONFLICT'
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
CONFLICT

echo "✅ services/ConflictChecker.js создан"

# 6. NotificationService
cat > src/services/NotificationService.js << 'NOTIFY'
/**
 * NOTIFICATION SERVICE
 * Уведомления и напоминания
 */

const NotificationService = {
  /**
   * Запросить разрешение на уведомления
   */
  async requestPermission() {
    if ('Notification' in window) {
      const permission = await Notification.requestPermission();
      return permission === 'granted';
    }
    return false;
  },
  
  /**
   * Показать уведомление
   */
  show(title, options = {}) {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, {
        icon: '/assets/icons/icon-192.png',
        badge: '/assets/icons/badge-72.png',
        ...options
      });
    }
    
    // Также отправляем событие для UI
    Events.emit('notification:show', { title, options });
  },
  
  /**
   * Напомнить о записи
   */
  remindEntry(entry, minutesBefore = 60) {
    const entryDateTime = new Date(entry.date + 'T' + entry.time);
    const notifyTime = new Date(entryDateTime.getTime() - minutesBefore * 60000);
    const now = new Date();
    
    if (notifyTime <= now) {
      this.show(`Скоро запись: ${entry.name}`, {
        body: `${entry.time} - ${entry.service}`,
        tag: `entry-${entry.id}`
      });
    }
  },
  
  /**
   * Проверить все напоминания
   */
  checkReminders() {
    const upcoming = EntryService.getUpcoming(10);
    upcoming.forEach(entry => {
      this.remindEntry(entry, 60); // За час
    });
  },
  
  /**
   * Утренний брифинг
   */
  morningBriefing() {
    const today = Utils.getToday();
    const entries = EntryService.getByDate(today);
    const notes = NoteService.getByDate(today);
    
    let message = `Доброе утро! Сегодня у тебя:\n`;
    message += `💼 ${entries.filter(e => e.category === 'work').length} клиента\n`;
    message += `👨👩‍👧 ${entries.filter(e => e.category === 'family').length} семейных дел\n`;
    if (notes.length > 0) {
      message += ` ${notes.length} заметок`;
    }
    
    this.show('Доброе утро! ☀️', { body: message });
  },
  
  /**
   * Вечерний итог
   */
  eveningSummary() {
    const today = Utils.getToday();
    const stats = EntryService.getStats(today, today);
    
    let message = `Сегодня:\n`;
    message += `✅ ${stats.done} выполнено\n`;
    message += `💰 ${stats.income}₽ заработано`;
    
    this.show('Молодец! 🎉', { body: message });
  }
};

window.NotificationService = NotificationService;
NOTIFY

echo "✅ services/NotificationService.js создан"

# 7. Создаём index.js для экспорта всех сервисов
cat > src/services/index.js << 'INDEX'
/**
 * SERVICES INDEX
 * Экспорт всех сервисов
 */

const Services = {
  Entry: window.EntryService,
  Note: window.NoteService,
  Price: window.PriceService,
  Family: window.FamilyService,
  Conflict: window.ConflictChecker,
  Notification: window.NotificationService
};

window.Services = Services;
INDEX

echo "✅ services/index.js создан"

echo ""
echo "✅ Все сервисы созданы!"
