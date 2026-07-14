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
