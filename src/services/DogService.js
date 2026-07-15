/**
 * DOG SERVICE
 * Управление событиями собаки
 */

const DogService = {
  // Типы событий
  eventTypes: {
    groomer: { label: ' Грумер', color: '#f59e0b' },
    vet: { label: '🏥 Ветеринар', color: '#ef4444' },
    walk: { label: ' Прогулка', color: '#10b981' },
    training: { label: '🎓 Дрессировка', color: '#8b5cf6' },
    other: { label: '📌 Другое', color: '#6b7280' }
  },

  // Создать событие
  create: function(data) {
    const entry = {
      ...data,
      category: 'dog',
      id: Utils.generateId(),
      createdAt: new Date().toISOString()
    };
    Store.addEntry(entry);
    Events.emit('entry:created', entry);
    return entry;
  },

  // Получить все события собаки
  getAll: function() {
    return Store.getEntries().filter(e => e.category === 'dog');
  },

  // Получить события по дате
  getByDate: function(date) {
    return this.getAll().filter(e => e.date === date);
  },

  // Обновить событие
  update: function(id, data) {
    Store.updateEntry(id, data);
    Events.emit('entry:updated', id);
  },

  // Удалить событие
  delete: function(id) {
    Store.deleteEntry(id);
    Events.emit('entry:deleted', id);
  }
};

window.DogService = DogService;
console.log('✅ DogService загружен');
