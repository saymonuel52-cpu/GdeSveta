/**
 * ENTRY MODEL
 * Модель записи с повторяющимися событиями
 */

const Entry = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      category: data.category || 'work',
      name: data.name || '',
      phone: data.phone || '',
      date: data.date || Utils.getToday(),
      time: data.time || Utils.getNow(),
      duration: data.duration || 60,
      service: data.service || '',
      zone: data.zone || '',
      notes: data.notes || '',
      price: data.price || 0,
      status: data.status || 'new',
      familyMemberId: data.familyMemberId || null,
      // Повторяющиеся события
      recurring: data.recurring || {
        enabled: false,
        type: 'daily', // daily, weekly, biweekly, monthly
        endDate: null,
        occurrences: null // количество повторений
      },
      parentEntryId: data.parentEntryId || null, // ID родительской записи
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(entry) {
    const errors = [];
    if (!entry.name || entry.name.trim() === '') {
      errors.push('Название обязательно');
    }
    if (!entry.date || !/^\d{4}-\d{2}-\d{2}$/.test(entry.date)) {
      errors.push('Неверная дата');
    }
    if (!entry.time || !/^\d{2}:\d{2}$/.test(entry.time)) {
      errors.push('Неверное время');
    }
    return { valid: errors.length === 0, errors };
  },
  
  getEndTime(entry) {
    return Utils.calcEndTime(entry.time, entry.duration);
  },
  
  getStatusLabel(status) {
    const labels = {
      new: 'Новая',
      confirmed: 'Подтверждена',
      done: 'Выполнена',
      cancelled: 'Отменена'
    };
    return labels[status] || status;
  },
  
  getRecurringLabel(type) {
    const labels = {
      daily: 'Каждый день',
      weekly: 'Каждую неделю',
      biweekly: 'Каждые 2 недели',
      monthly: 'Каждый месяц'
    };
    return labels[type] || type;
  }
};

window.Entry = Entry;
