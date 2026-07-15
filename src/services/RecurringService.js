/**
 * RECURRING SERVICE
 * Управление повторяющимися событиями
 */

const RecurringService = {
  // Типы повторений
  repeatTypes: {
    daily: { label: 'Ежедневно', value: 'daily' },
    weekdays: { label: 'По будням (Пн-Пт)', value: 'weekdays' },
    weekly: { label: 'Еженедельно', value: 'weekly' },
    monthly: { label: 'Ежемесячно', value: 'monthly' }
  },

  // Создать повторяющееся событие
  create: function(data) {
    const recurring = {
      id: Utils.generateId(),
      name: data.name,
      service: data.service,
      time: data.time,
      duration: data.duration,
      category: data.category,
      repeatType: data.repeatType,
      startDate: data.startDate,
      endDate: data.endDate,
      daysOfWeek: data.daysOfWeek || [], // для weekly: [1,3,5] = Пн,Ср,Пт
      excludeDates: data.excludeDates || [], // праздники, каникулы
      price: data.price || 0,
      notes: data.notes || '',
      createdAt: new Date().toISOString()
    };

    // Сохраняем в специальное хранилище
    const recurringList = JSON.parse(Storage.get('recurringEvents', '[]'));
    recurringList.push(recurring);
    Storage.set('recurringEvents', JSON.stringify(recurringList));

    // Генерируем события до указанной даты
    this.generateEvents(recurring);

    return recurring;
  },

  // Сгенерировать события из шаблона
  generateEvents: function(recurring) {
    const start = new Date(recurring.startDate);
    const end = new Date(recurring.endDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let currentDate = new Date(start);
    const generatedEntries = [];

    while (currentDate <= end) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const dayOfWeek = currentDate.getDay();

      // Проверяем, подходит ли день
      let shouldCreate = false;

      switch (recurring.repeatType) {
        case 'daily':
          shouldCreate = true;
          break;
        case 'weekdays':
          shouldCreate = dayOfWeek >= 1 && dayOfWeek <= 5; // Пн-Пт
          break;
        case 'weekly':
          shouldCreate = recurring.daysOfWeek.includes(dayOfWeek);
          break;
        case 'monthly':
          shouldCreate = currentDate.getDate() === start.getDate();
          break;
      }

      // Проверяем, не исключена ли дата
      const isExcluded = recurring.excludeDates.some(exclude => {
        const excludeDate = new Date(exclude).toISOString().split('T')[0];
        return excludeDate === dateStr;
      });

      // Создаём событие если нужно и дата не в прошлом
      if (shouldCreate && !isExcluded && currentDate >= today) {
        const entry = {
          id: Utils.generateId(),
          name: recurring.name,
          service: recurring.service,
          category: recurring.category,
          date: dateStr,
          time: recurring.time,
          duration: recurring.duration,
          price: recurring.price,
          notes: recurring.notes + ' (повторяющееся)',
          status: 'new',
          recurringId: recurring.id,
          createdAt: new Date().toISOString()
        };

        // Проверяем, нет ли уже такого события
        const exists = Store.getEntries().some(e => 
          e.date === entry.date && 
          e.time === entry.time && 
          e.recurringId === recurring.id
        );

        if (!exists) {
          Store.addEntry(entry);
          generatedEntries.push(entry);
        }
      }

      // Переходим к следующему дню
      currentDate.setDate(currentDate.getDate() + 1);
    }

    Events.emit('entry:created', generatedEntries);
    return generatedEntries;
  },

  // Получить все повторяющиеся шаблоны
  getAll: function() {
    return JSON.parse(Storage.get('recurringEvents', '[]'));
  },

  // Удалить шаблон и все связанные события
  delete: function(id) {
    const recurringList = this.getAll();
    const filtered = recurringList.filter(r => r.id !== id);
    Storage.set('recurringEvents', JSON.stringify(filtered));

    // Удаляем все события этого шаблона
    const entries = Store.getEntries();
    const filteredEntries = entries.filter(e => e.recurringId !== id);
    Storage.set('entries', JSON.stringify(filteredEntries));

    Events.emit('entry:deleted', id);
  },

  // Обновить шаблон
  update: function(id, data) {
    const recurringList = this.getAll();
    const index = recurringList.findIndex(r => r.id === id);
    
    if (index !== -1) {
      recurringList[index] = { ...recurringList[index], ...data };
      Storage.set('recurringEvents', JSON.stringify(recurringList));
      
      // Перегенерируем события
      this.generateEvents(recurringList[index]);
      
      Events.emit('entry:updated', id);
    }
  }
};

window.RecurringService = RecurringService;
console.log('✅ RecurringService загружен');
