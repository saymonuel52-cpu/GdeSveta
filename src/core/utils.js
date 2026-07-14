/**
 * UTILS MODULE
 * Набор утилит для работы с данными
 */

const Utils = (() => {
  /**
   * Сгенерировать уникальный ID
   * @returns {number} Уникальный ID
   */
  function generateId() {
    return Date.now() + Math.random();
  }
  
  /**
   * Форматировать дату
   * @param {string|Date} date - Дата
   * @param {string} format - Формат (short, long, full)
   * @returns {string} Отформатированная дата
   */
  function formatDate(date, format = 'short') {
    const d = typeof date === 'string' ? new Date(date) : date;
    
    const options = {
      short: { day: 'numeric', month: 'short' },
      long: { day: 'numeric', month: 'long', weekday: 'short' },
      full: { day: 'numeric', month: 'long', year: 'numeric', weekday: 'long' }
    };
    
    return d.toLocaleDateString('ru-RU', options[format] || options.short);
  }
  
  /**
   * Форматировать время
   * @param {string} time - Время в формате HH:MM
   * @returns {string} Отформатированное время
   */
  function formatTime(time) {
    return time; // Уже в нужном формате
  }
  
  /**
   * Конвертировать время в минуты
   * @param {string} time - Время в формате HH:MM
   * @returns {number} Минуты с начала дня
   */
  function timeToMinutes(time) {
    const [h, m] = time.split(':').map(Number);
    return h * 60 + m;
  }
  
  /**
   * Конвертировать минуты в время
   * @param {number} mins - Минуты с начала дня
   * @returns {string} Время в формате HH:MM
   */
  function minutesToTime(mins) {
    const h = Math.floor(mins / 60) % 24;
    const m = mins % 60;
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  }
  
  /**
   * Рассчитать время окончания
   * @param {string} startTime - Время начала
   * @param {number} duration - Длительность в минутах
   * @returns {string} Время окончания
   */
  function calcEndTime(startTime, duration) {
    if (!startTime || !duration) return '';
    return minutesToTime(timeToMinutes(startTime) + parseInt(duration));
  }
  
  /**
   * Получить сегодняшнюю дату
   * @returns {string} Дата в формате YYYY-MM-DD
   */
  function getToday() {
    return new Date().toISOString().split('T')[0];
  }
  
  /**
   * Получить текущее время
   * @returns {string} Время в формате HH:MM
   */
  function getNow() {
    const now = new Date();
    return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  }
  
  /**
   * Проверить валидность email
   * @param {string} email - Email
   * @returns {boolean} Валиден
   */
  function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
  
  /**
   * Проверить валидность телефона
   * @param {string} phone - Телефон
   * @returns {boolean} Валиден
   */
  function isValidPhone(phone) {
    return /^\+?[\d\s\-\(\)]{10,}$/.test(phone);
  }
  
  /**
   * Экранировать HTML
   * @param {string} str - Строка
   * @returns {string} Экранированная строка
   */
  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  /**
   * Debounce функция
   * @param {function} func - Функция
   * @param {number} wait - Задержка в мс
   * @returns {function} Debounced функция
   */
  function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }
  
  // Публичный API
  return {
    generateId,
    formatDate,
    formatTime,
    timeToMinutes,
    minutesToTime,
    calcEndTime,
    getToday,
    getNow,
    isValidEmail,
    isValidPhone,
    escapeHtml,
    debounce
  };
})();

// Экспорт
window.Utils = Utils;
