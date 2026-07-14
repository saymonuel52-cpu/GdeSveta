/**
 * STORAGE MODULE
 * Единая точка доступа к localStorage
 * - Автоматическая сериализация
 * - Обработка ошибок
 * - Версионирование данных
 * - Миграции при обновлении
 */

const Storage = (() => {
  const VERSION_KEY = 'gdesveta_version';
  const CURRENT_VERSION = 1;
  
  /**
   * Получить данные из хранилища
   * @param {string} key - Ключ
   * @param {*} defaultValue - Значение по умолчанию
   * @returns {*} Данные
   */
  function get(key, defaultValue = null) {
    try {
      const item = localStorage.getItem(key);
      if (item === null) return defaultValue;
      return JSON.parse(item);
    } catch (error) {
      console.error(`[Storage] Ошибка чтения ${key}:`, error);
      return defaultValue;
    }
  }
  
  /**
   * Сохранить данные в хранилище
   * @param {string} key - Ключ
   * @param {*} value - Данные
   * @returns {boolean} Успех
   */
  function set(key, value) {
    try {
      const json = JSON.stringify(value);
      localStorage.setItem(key, json);
      return true;
    } catch (error) {
      console.error(`[Storage] Ошибка записи ${key}:`, error);
      return false;
    }
  }
  
  /**
   * Удалить данные из хранилища
   * @param {string} key - Ключ
   */
  function remove(key) {
    try {
      localStorage.removeItem(key);
    } catch (error) {
      console.error(`[Storage] Ошибка удаления ${key}:`, error);
    }
  }
  
  /**
   * Очистить всё хранилище
   */
  function clear() {
    try {
      localStorage.clear();
    } catch (error) {
      console.error('[Storage] Ошибка очистки:', error);
    }
  }
  
  /**
   * Получить все ключи
   * @returns {string[]} Массив ключей
   */
  function keys() {
    try {
      return Object.keys(localStorage);
    } catch (error) {
      console.error('[Storage] Ошибка получения ключей:', error);
      return [];
    }
  }
  
  /**
   * Экспорт всех данных
   * @returns {object} Все данные
   */
  function exportAll() {
    const data = {};
    keys().forEach(key => {
      data[key] = get(key);
    });
    return data;
  }
  
  /**
   * Импорт данных
   * @param {object} data - Данные для импорта
   */
  function importAll(data) {
    Object.keys(data).forEach(key => {
      set(key, data[key]);
    });
  }
  
  /**
   * Проверить версию и выполнить миграцию
   */
  function checkVersion() {
    const storedVersion = get(VERSION_KEY, 0);
    
    if (storedVersion < CURRENT_VERSION) {
      console.log(`[Storage] Миграция с v${storedVersion} на v${CURRENT_VERSION}`);
      migrate(storedVersion, CURRENT_VERSION);
      set(VERSION_KEY, CURRENT_VERSION);
    }
  }
  
  /**
   * Миграция данных между версиями
   * @param {number} from - Старая версия
   * @param {number} to - Новая версия
   */
  function migrate(from, to) {
    // Пример миграции:
    // if (from === 0 && to === 1) {
    //   const oldData = get('old_key');
    //   set('new_key', transformData(oldData));
    //   remove('old_key');
    // }
    console.log('[Storage] Миграция завершена');
  }
  
  // Публичный API
  return {
    get,
    set,
    remove,
    clear,
    keys,
    exportAll,
    importAll,
    checkVersion
  };
})();

// Экспорт для использования в других модулях
window.Storage = Storage;
