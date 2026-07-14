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
