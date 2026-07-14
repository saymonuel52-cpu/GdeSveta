/**
 * STORE MODULE
 * Централизованное хранилище состояния приложения
 * - Автоматическое сохранение
 * - Подписка на изменения
 * - Единый источник правды
 */

const Store = (() => {
  const STORAGE_KEY = 'gdesveta_store';
  
  // Начальное состояние
  let state = {
    entries: [],
    notes: [],
    priceList: [],
    familyMembers: [],
    ui: {
      currentTab: 'calendar',
      selectedDate: Utils.getToday(),
      currentDate: new Date()
    }
  };
  
  // Подписчики на изменения
  const subscribers = [];
  
  /**
   * Инициализация хранилища
   */
  function init() {
    const saved = Storage.get(STORAGE_KEY);
    if (saved) {
      state = { ...state, ...saved };
    }
    
    // Проверка версии и миграция
    Storage.checkVersion();
    
    console.log('[Store] Инициализирован');
  }
  
  /**
   * Получить состояние
   * @returns {object} Текущее состояние
   */
  function getState() {
    return { ...state };
  }
  
  /**
   * Обновить состояние
   * @param {object} updates - Обновления
   */
  function setState(updates) {
    state = { ...state, ...updates };
    save();
    notify();
  }
  
  /**
   * Обновить UI состояние
   * @param {object} updates - Обновления UI
   */
  function setUI(updates) {
    state.ui = { ...state.ui, ...updates };
    notify();
  }
  
  /**
   * Сохранить состояние в localStorage
   */
  function save() {
    Storage.set(STORAGE_KEY, state);
  }
  
  /**
   * Подписаться на изменения
   * @param {function} callback - Функция-обработчик
   * @returns {function} Функция отписки
   */
  function subscribe(callback) {
    subscribers.push(callback);
    return () => {
      const index = subscribers.indexOf(callback);
      if (index > -1) {
        subscribers.splice(index, 1);
      }
    };
  }
  
  /**
   * Уведомить подписчиков об изменениях
   */
  function notify() {
    subscribers.forEach(callback => {
      try {
        callback(getState());
      } catch (error) {
        console.error('[Store] Ошибка в подписчике:', error);
      }
    });
  }
  
  /**
   * Получить записи
   * @returns {Array} Массив записей
   */
  function getEntries() {
    return state.entries;
  }
  
  /**
   * Добавить запись
   * @param {object} entry - Запись
   */
  function addEntry(entry) {
    state.entries.push(entry);
    save();
    notify();
    Events.emit('entry:added', entry);
  }
  
  /**
   * Обновить запись
   * @param {number} id - ID записи
   * @param {object} updates - Обновления
   */
  function updateEntry(id, updates) {
    const index = state.entries.findIndex(e => e.id === id);
    if (index > -1) {
      state.entries[index] = { ...state.entries[index], ...updates };
      save();
      notify();
      Events.emit('entry:updated', state.entries[index]);
    }
  }
  
  /**
   * Удалить запись
   * @param {number} id - ID записи
   */
  function deleteEntry(id) {
    const entry = state.entries.find(e => e.id === id);
    state.entries = state.entries.filter(e => e.id !== id);
    save();
    notify();
    Events.emit('entry:deleted', entry);
  }
  
  /**
   * Получить заметки
   * @returns {Array} Массив заметок
   */
  function getNotes() {
    return state.notes;
  }
  
  /**
   * Добавить заметку
   * @param {object} note - Заметка
   */
  function addNote(note) {
    state.notes.push(note);
    save();
    notify();
    Events.emit('note:added', note);
  }
  
  /**
   * Обновить заметку
   * @param {number} id - ID заметки
   * @param {object} updates - Обновления
   */
  function updateNote(id, updates) {
    const index = state.notes.findIndex(n => n.id === id);
    if (index > -1) {
      state.notes[index] = { ...state.notes[index], ...updates };
      save();
      notify();
      Events.emit('note:updated', state.notes[index]);
    }
  }
  
  /**
   * Удалить заметку
   * @param {number} id - ID заметки
   */
  function deleteNote(id) {
    const note = state.notes.find(n => n.id === id);
    state.notes = state.notes.filter(n => n.id !== id);
    save();
    notify();
    Events.emit('note:deleted', note);
  }
  
  /**
   * Получить прайс-лист
   * @returns {Array} Массив услуг
   */
  function getPriceList() {
    return state.priceList;
  }
  
  /**
   * Добавить услугу в прайс
   * @param {object} item - Услуга
   */
  function addPriceItem(item) {
    state.priceList.push(item);
    save();
    notify();
    Events.emit('price:added', item);
  }
  
  /**
   * Удалить услугу из прайса
   * @param {number} id - ID услуги
   */
  function deletePriceItem(id) {
    const item = state.priceList.find(p => p.id === id);
    state.priceList = state.priceList.filter(p => p.id !== id);
    save();
    notify();
    Events.emit('price:deleted', item);
  }
  
  /**
   * Получить членов семьи
   * @returns {Array} Массив членов семьи
   */
  function getFamilyMembers() {
    return state.familyMembers;
  }
  
  /**
   * Добавить члена семьи
   * @param {object} member - Член семьи
   */
  function addFamilyMember(member) {
    state.familyMembers.push(member);
    save();
    notify();
    Events.emit('family:added', member);
  }
  
  /**
   * Удалить члена семьи
   * @param {number} id - ID члена семьи
   */
  function deleteFamilyMember(id) {
    const member = state.familyMembers.find(m => m.id === id);
    state.familyMembers = state.familyMembers.filter(m => m.id !== id);
    save();
    notify();
    Events.emit('family:deleted', member);
  }
  
  /**
   * Экспорт всех данных
   * @returns {object} Все данные
   */
  function exportData() {
    return {
      entries: state.entries,
      notes: state.notes,
      priceList: state.priceList,
      familyMembers: state.familyMembers
    };
  }
  
  /**
   * Импорт данных
   * @param {object} data - Данные для импорта
   */
  function importData(data) {
    state.entries = data.entries || [];
    state.notes = data.notes || [];
    state.priceList = data.priceList || [];
    state.familyMembers = data.familyMembers || [];
    save();
    notify();
    Events.emit('store:imported');
  }
  
  // Публичный API
  return {
    init,
    getState,
    setState,
    setUI,
    subscribe,
    getEntries,
    addEntry,
    updateEntry,
    deleteEntry,
    getNotes,
    addNote,
    updateNote,
    deleteNote,
    getPriceList,
    addPriceItem,
    deletePriceItem,
    getFamilyMembers,
    addFamilyMember,
    deleteFamilyMember,
    exportData,
    importData
  };
})();

// Экспорт
window.Store = Store;
