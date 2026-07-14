/**
 * ENTRY SERVICE
 * С поддержкой повторяющихся событий
 */

const EntryService = {
  getAll() {
    return Store.getEntries();
  },
  
  getByDate(date) {
    return Store.getEntries().filter(e => e.date === date && e.status !== 'cancelled');
  },
  
  getByCategory(category) {
    return Store.getEntries().filter(e => e.category === category && e.status !== 'cancelled');
  },
  
  getByPeriod(startDate, endDate) {
    return Store.getEntries().filter(e => {
      return e.date >= startDate && e.date <= endDate && e.status !== 'cancelled';
    });
  },
  
  create(data, force = false) {
    const entry = Entry.create(data);
    const validation = Entry.validate(entry);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    // Проверка конфликтов только для рабочих записей
    if (entry.category === 'work' && !force) {
      const conflict = this.checkConflict(entry);
      if (conflict) {
        throw new Error(`Конфликт с записью: ${conflict.name}`);
      }
    }
    
    Store.addEntry(entry);
    Events.emit('entry:created', entry);
    
    // Если повторяющееся — создаём серии
    if (entry.recurring && entry.recurring.enabled) {
      this.createRecurringEntries(entry);
    }
    
    return entry;
  },
  
  /**
   * Создать серию повторяющихся записей
   */
  createRecurringEntries(parentEntry) {
    const recurring = parentEntry.recurring;
    if (!recurring || !recurring.enabled) return;
    
    const startDate = new Date(parentEntry.date);
    let endDate = recurring.endDate ? new Date(recurring.endDate) : null;
    const maxOccurrences = recurring.occurrences || 52; // максимум 52 повторения
    
    const occurrences = [];
    let currentDate = new Date(startDate);
    let count = 0;
    
    while ((!endDate || currentDate <= endDate) && count < maxOccurrences) {
      count++;
      
      // Создаём следующую запись
      const nextDate = new Date(currentDate);
      const dateStr = nextDate.toISOString().split('T')[0];
      
      // Не создаём дубликат первой записи
      if (dateStr !== parentEntry.date) {
        const newEntry = Entry.create({
          ...parentEntry,
          date: dateStr,
          parentEntryId: parentEntry.id,
          recurring: { enabled: false } // У дочерних записей повторение отключено
        });
        
        // Проверяем конфликты
        const conflict = this.checkConflict(newEntry);
        if (!conflict) {
          Store.addEntry(newEntry);
          occurrences.push(newEntry);
        }
      }
      
      // Переходим к следующей дате
      if (recurring.type === 'daily') {
        currentDate.setDate(currentDate.getDate() + 1);
      } else if (recurring.type === 'weekly') {
        currentDate.setDate(currentDate.getDate() + 7);
      } else if (recurring.type === 'biweekly') {
        currentDate.setDate(currentDate.getDate() + 14);
      } else if (recurring.type === 'monthly') {
        currentDate.setMonth(currentDate.getMonth() + 1);
      }
    }
    
    if (occurrences.length > 0) {
      Events.emit('recurring:created', {
        parent: parentEntry,
        occurrences: occurrences.length
      });
    }
    
    return occurrences;
  },
  
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
  
  delete(id, deleteAllRecurring = false) {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) throw new Error('Запись не найдена');
    
    // Если это родительская запись и нужно удалить все
    if (deleteAllRecurring && entry.recurring && entry.recurring.enabled) {
      const allEntries = Store.getEntries();
      const recurringEntries = allEntries.filter(e => e.parentEntryId === id);
      
      recurringEntries.forEach(e => {
        Store.deleteEntry(e.id);
      });
    }
    
    Store.deleteEntry(id);
    Events.emit('entry:deleted', id);
  },
  
  changeStatus(id, status) {
    return this.update(id, { status });
  },
  
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
  
  duplicate(id, newDate) {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) throw new Error('Запись не найдена');
    
    const duplicate = Entry.create({
      ...entry,
      date: newDate || entry.date,
      name: entry.name + ' (копия)',
      status: 'new',
      recurring: { enabled: false }
    });
    
    Store.addEntry(duplicate);
    return duplicate;
  },
  
  getUpcoming(limit = 5) {
    const today = Utils.getToday();
    return this.getAll()
      .filter(e => e.date >= today && e.status !== 'cancelled')
      .sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time))
      .slice(0, limit);
  },
  
  clearAll() {
    Storage.set('gdesveta_store', {
      entries: [],
      notes: Store.getNotes(),
      priceList: Store.getPriceList(),
      familyMembers: Store.getFamilyMembers()
    });
    Events.emit('store:cleared');
  },
  
  /**
   * Получить все повторяющиеся записи
   */
  getRecurringEntries() {
    return Store.getEntries().filter(e => 
      e.recurring && e.recurring.enabled
    );
  },
  
  /**
   * Удалить все будущие повторения записи
   */
  deleteFutureRecurring(parentId) {
    const allEntries = Store.getEntries();
    const today = Utils.getToday();
    
    const futureRecurring = allEntries.filter(e => 
      e.parentEntryId === parentId && e.date >= today
    );
    
    futureRecurring.forEach(e => {
      Store.deleteEntry(e.id);
    });
    
    return futureRecurring.length;
  }
};

window.EntryService = EntryService;
