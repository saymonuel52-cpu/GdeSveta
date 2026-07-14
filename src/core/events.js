/**
 * EVENTS MODULE
 * Система событий (Pub/Sub) для связи между модулями
 * - Модули общаются без прямых зависимостей
 * - Легко тестировать
 * - Легко расширять
 */

const Events = (() => {
  const listeners = {};
  
  /**
   * Подписаться на событие
   * @param {string} event - Имя события
   * @param {function} callback - Функция-обработчик
   * @returns {function} Функция отписки
   */
  function on(event, callback) {
    if (!listeners[event]) {
      listeners[event] = [];
    }
    
    listeners[event].push(callback);
    
    // Возвращаем функцию отписки
    return () => off(event, callback);
  }
  
  /**
   * Отписаться от события
   * @param {string} event - Имя события
   * @param {function} callback - Функция-обработчик
   */
  function off(event, callback) {
    if (!listeners[event]) return;
    
    listeners[event] = listeners[event].filter(cb => cb !== callback);
  }
  
  /**
   * Отправить событие
   * @param {string} event - Имя события
   * @param {*} data - Данные события
   */
  function emit(event, data) {
    if (!listeners[event]) return;
    
    listeners[event].forEach(callback => {
      try {
        callback(data);
      } catch (error) {
        console.error(`[Events] Ошибка в обработчике ${event}:`, error);
      }
    });
  }
  
  /**
   * Подписаться на событие один раз
   * @param {string} event - Имя события
   * @param {function} callback - Функция-обработчик
   */
  function once(event, callback) {
    const unsubscribe = on(event, (data) => {
      callback(data);
      unsubscribe();
    });
  }
  
  /**
   * Отписаться от всех событий
   */
  function clear() {
    Object.keys(listeners).forEach(event => {
      listeners[event] = [];
    });
  }
  
  // Публичный API
  return {
    on,
    off,
    emit,
    once,
    clear
  };
})();

// Экспорт
window.Events = Events;
