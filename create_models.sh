#!/bin/bash
echo "🎯 Создаю модели данных..."

mkdir -p src/models

# 1. Модель Entry (Запись)
cat > src/models/Entry.js << 'ENTRY'
/**
 * ENTRY MODEL
 * Модель записи (рабочей или семейной)
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
      service: data.service || 'Другое',
      zone: data.zone || '',
      notes: data.notes || '',
      price: data.price || 0,
      status: data.status || 'new',
      familyMemberId: data.familyMemberId || null,
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(entry) {
    const errors = [];
    if (!entry.name || entry.name.trim() === '') errors.push('Название обязательно');
    if (!entry.date) errors.push('Дата обязательна');
    if (!entry.time) errors.push('Время обязательно');
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
  }
};

window.Entry = Entry;
ENTRY

echo "✅ models/Entry.js создан"

# 2. Модель Note (Заметка)
cat > src/models/Note.js << 'NOTE'
/**
 * NOTE MODEL
 * Модель заметки
 */

const Note = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      title: data.title || '',
      text: data.text || '',
      category: data.category || 'general',
      date: data.date || null,
      priority: data.priority || 'normal',
      completed: data.completed || false,
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(note) {
    const errors = [];
    if (!note.title || note.title.trim() === '') errors.push('Заголовок обязателен');
    return { valid: errors.length === 0, errors };
  },
  
  getCategoryIcon(category) {
    const icons = {
      general: '',
      important: '⭐',
      shopping: '🛒',
      ideas: '',
      reminder: '⏰'
    };
    return icons[category] || '📝';
  }
};

window.Note = Note;
NOTE

echo "✅ models/Note.js создан"

# 3. Модель PriceItem (Услуга прайса)
cat > src/models/PriceItem.js << 'PRICE'
/**
 * PRICE ITEM MODEL
 * Модель услуги в прайс-листе
 */

const PriceItem = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      name: data.name || '',
      service: data.service || 'Шугаринг',
      duration: data.duration || 60,
      price: data.price || 0,
      description: data.description || '',
      active: data.active !== false,
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(item) {
    const errors = [];
    if (!item.name || item.name.trim() === '') errors.push('Название услуги обязательно');
    if (item.price < 0) errors.push('Цена не может быть отрицательной');
    if (item.duration <= 0) errors.push('Длительность должна быть больше 0');
    return { valid: errors.length === 0, errors };
  },
  
  getFormattedPrice(price) {
    return `${price}₽`;
  },
  
  getFormattedDuration(minutes) {
    if (minutes < 60) return `${minutes} мин`;
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return mins > 0 ? `${hours} ч ${mins} мин` : `${hours} ч`;
  }
};

window.PriceItem = PriceItem;
PRICE

echo "✅ models/PriceItem.js создан"

# 4. Модель FamilyMember (Член семьи)
cat > src/models/FamilyMember.js << 'FAMILY'
/**
 * FAMILY MEMBER MODEL
 * Модель члена семьи
 */

const FamilyMember = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      name: data.name || '',
      role: data.role || 'child',
      age: data.age || null,
      phone: data.phone || '',
      school: data.school || '',
      circles: data.circles || [],
      breed: data.breed || '',
      photo: data.photo || null,
      active: data.active !== false,
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(member) {
    const errors = [];
    if (!member.name || member.name.trim() === '') errors.push('Имя обязательно');
    return { valid: errors.length === 0, errors };
  },
  
  getRoleIcon(role) {
    const icons = {
      child: '👶',
      adult: '👤',
      dog: '🐕'
    };
    return icons[role] || '👤';
  },
  
  getRoleLabel(role) {
    const labels = {
      child: 'Ребёнок',
      adult: 'Взрослый',
      dog: 'Собака'
    };
    return labels[role] || role;
  },
  
  getCirclesText(circles) {
    if (!circles || circles.length === 0) return '';
    return circles.join(', ');
  }
};

window.FamilyMember = FamilyMember;
FAMILY

echo "✅ models/FamilyMember.js создан"

# 5. Модель User (Пользователь)
cat > src/models/User.js << 'USER'
/**
 * USER MODEL
 * Модель пользователя (мастера)
 */

const User = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      name: data.name || 'Света',
      phone: data.phone || '',
      email: data.email || '',
      workStart: data.workStart || '09:00',
      workEnd: data.workEnd || '21:00',
      workDays: data.workDays || [1, 2, 3, 4, 5],
      avatar: data.avatar || null,
      settings: {
        darkTheme: false,
        notifications: true,
        language: 'ru'
      },
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(user) {
    const errors = [];
    if (!user.name || user.name.trim() === '') errors.push('Имя обязательно');
    return { valid: errors.length === 0, errors };
  },
  
  isWorkDay(date) {
    const day = new Date(date).getDay();
    const adjustedDay = day === 0 ? 6 : day - 1;
    return User.get().workDays.includes(adjustedDay);
  },
  
  get() {
    return Storage.get('current_user', User.create({}));
  },
  
  save(data) {
    const user = { ...User.get(), ...data, updatedAt: new Date().toISOString() };
    Storage.set('current_user', user);
    return user;
  }
};

window.User = User;
USER

echo "✅ models/User.js создан"

# 6. Создаём index.js для экспорта всех моделей
cat > src/models/index.js << 'INDEX'
/**
 * MODELS INDEX
 * Экспорт всех моделей
 */

// Модели уже загружены в window через отдельные скрипты
const Models = {
  Entry: window.Entry,
  Note: window.Note,
  PriceItem: window.PriceItem,
  FamilyMember: window.FamilyMember,
  User: window.User
};

window.Models = Models;
INDEX

echo "✅ models/index.js создан"

echo ""
echo "✅ Все модели созданы!"
