/**
 * FAMILY SHARE SERVICE
 * Семейный доступ: PIN, общий список задач, экспорт расписания
 */

const FamilyShare = {
  /**
   * PIN-код (хранится хешированным)
   */
  PIN_KEY: 'gdesveta_pin',
  PIN_ENABLED_KEY: 'gdesveta_pin_enabled',
  
  /**
   * Установить PIN
   */
  setPin(pin) {
    if (!pin || pin.length < 4) {
      throw new Error('PIN должен быть минимум 4 цифры');
    }
    if (!/^\d{4,6}$/.test(pin)) {
      throw new Error('PIN должен содержать только цифры (4-6)');
    }
    Storage.set(this.PIN_KEY, pin); // В реальном приложении — хеш
    Storage.set(this.PIN_ENABLED_KEY, true);
    return true;
  },
  
  /**
   * Проверить PIN
   */
  checkPin(pin) {
    const saved = Storage.get(this.PIN_KEY);
    return saved === pin;
  },
  
  /**
   * Удалить PIN
   */
  removePin() {
    Storage.remove(this.PIN_KEY);
    Storage.remove(this.PIN_ENABLED_KEY);
  },
  
  /**
   * Включён ли PIN
   */
  isPinEnabled() {
    return Storage.get(this.PIN_ENABLED_KEY, false);
  },
  
  /**
   * Экспорт расписания на день в текст
   */
  exportDaySchedule(date) {
    const entries = EntryService.getByDate(date);
    const notes = NoteService.getByDate(date);
    const dayName = Utils.formatDate(date, 'long');
    
    let text = `📅 ГдеСвета — ${dayName}\n\n`;
    
    if (entries.length > 0) {
      text += `⏰ ЗАПИСИ:\n`;
      entries.forEach(e => {
        const endTime = Utils.calcEndTime(e.time, e.duration);
        const icon = e.category === 'work' ? '💼' : e.category === 'family' ? '👨‍👧' : '🐕';
        text += `${icon} ${e.time}-${endTime} ${e.name}`;
        if (e.price > 0) text += ` (${e.price}₽)`;
        text += `\n`;
      });
      text += `\n`;
    }
    
    if (notes.length > 0) {
      text += ` ЗАМЕТКИ:\n`;
      notes.forEach(n => {
        const icon = Note.getCategoryIcon(n.category);
        text += `${icon} ${n.title}\n`;
      });
    }
    
    if (entries.length === 0 && notes.length === 0) {
      text += `Свободный день! 🌸\n`;
    }
    
    return text;
  },
  
  /**
   * Поделиться через системное меню (Web Share API)
   */
  async shareSchedule(date) {
    const text = this.exportDaySchedule(date);
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'Расписание на ' + Utils.formatDate(date, 'short'),
          text: text
        });
        return true;
      } catch (error) {
        console.log('[Share] Отменено пользователем');
        return false;
      }
    } else {
      // Фоллбэк: копирование в буфер
      try {
        await navigator.clipboard.writeText(text);
        Modal.alert('📋 Скопировано в буфер обмена!');
        return true;
      } catch (error) {
        Modal.alert('❌ Не удалось поделиться: ' + error.message);
        return false;
      }
    }
  },
  
  /**
   * Экспорт недели
   */
  exportWeekSchedule(startDate) {
    const start = new Date(startDate);
    const end = new Date(start);
    end.setDate(end.getDate() + 6);
    
    let text = `📅 ГдеСвета — неделя с ${Utils.formatDate(startDate, 'short')}\n\n`;
    
    for (let d = 0; d < 7; d++) {
      const date = new Date(start);
      date.setDate(date.getDate() + d);
      const dateStr = date.toISOString().split('T')[0];
      const dayName = Utils.formatDate(dateStr, 'short');
      
      const entries = EntryService.getByDate(dateStr);
      if (entries.length > 0) {
        text += `📆 ${dayName}:\n`;
        entries.forEach(e => {
          text += `  ${e.time} ${e.name}\n`;
        });
        text += `\n`;
      }
    }
    
    return text;
  },
  
  /**
   * Семейный список задач (общий)
   */
  TASKS_KEY: 'gdesveta_family_tasks',
  
  getTasks() {
    return Storage.get(this.TASKS_KEY, []);
  },
  
  addTask(task) {
    const tasks = this.getTasks();
    const newTask = {
      id: Utils.generateId(),
      text: task.text,
      category: task.category || 'general',
      assignedTo: task.assignedTo || null,
      completed: false,
      createdAt: new Date().toISOString()
    };
    tasks.push(newTask);
    Storage.set(this.TASKS_KEY, tasks);
    Events.emit('task:added', newTask);
    return newTask;
  },
  
  toggleTask(id) {
    const tasks = this.getTasks();
    const task = tasks.find(t => t.id === id);
    if (task) {
      task.completed = !task.completed;
      task.completedAt = task.completed ? new Date().toISOString() : null;
      Storage.set(this.TASKS_KEY, tasks);
      Events.emit('task:toggled', task);
    }
    return task;
  },
  
  deleteTask(id) {
    const tasks = this.getTasks().filter(t => t.id !== id);
    Storage.set(this.TASKS_KEY, tasks);
    Events.emit('task:deleted', id);
  },
  
  getActiveTasks() {
    return this.getTasks().filter(t => !t.completed);
  },
  
  getCompletedTasks() {
    return this.getTasks().filter(t => t.completed);
  },
  
  clearCompletedTasks() {
    const tasks = this.getTasks().filter(t => !t.completed);
    Storage.set(this.TASKS_KEY, tasks);
  }
};

window.FamilyShare = FamilyShare;
