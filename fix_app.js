// Удаляем дублирующийся код авто-очистки (если есть)
sed -i '/АВТО-ОЧИСТКА SW/,/console.log.*Кнопка работает/d' app.js

# Добавляем правильный код в КОНЕЦ файла
cat >> app.js << 'JSEND'

// === ИСПРАВЛЕННЫЙ ОБРАБОТЧИК КНОПКИ ===
(function() {
  // Ждём полной загрузки страницы
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initButton);
  } else {
    initButton();
  }
  
  function initButton() {
    const addBtn = document.getElementById('addAppBtnFixed');
    if (addBtn) {
      addBtn.addEventListener('click', () => {
        // Ищем функцию для открытия модалки
        const possibleNames = ['openAddModal', 'showModal', 'openModal', 'showAddForm', 'addEntry', 'createEntry'];
        for (let name of possibleNames) {
          if (typeof window[name] === 'function') {
            window[name]();
            return;
          }
        }
        // Если не нашли — показываем тестовое сообщение
        alert('✅ Кнопка работает! Теперь нужно подключить вашу функцию модалки.');
      });
      console.log('✅ Кнопка "+ Добавить запись" активна');
    }
  }
})();
JSEND

echo "✅ app.js исправлен"
