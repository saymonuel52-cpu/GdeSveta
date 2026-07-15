/**
 * ГдеСвета - Полноценная рабочая версия
 */

console.log(' ГдеСвета загружается...');

// Глобальные функции
window.switchTab = function(tabName) {
  console.log(' Переключение на:', tabName);
  
  // Скрываем все вкладки
  document.querySelectorAll('.tab-content').forEach(tab => {
    tab.style.display = 'none';
    tab.classList.remove('active');
  });
  
  // Убираем active с кнопок
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.classList.remove('active');
  });
  
  // Показываем нужную вкладку
  const targetTab = document.getElementById('tab-' + tabName);
  const targetBtn = document.querySelector('.nav-item[data-tab="' + tabName + '"]');
  
  if (targetTab) {
    targetTab.style.display = 'block';
    targetTab.classList.add('active');
  }
  
  if (targetBtn) {
    targetBtn.classList.add('active');
  }
  
  // Инициализируем контент
  setTimeout(function() {
    if (tabName === 'calendar' && typeof CalendarView !== 'undefined') {
      CalendarView.render();
    } else if (tabName === 'work' && typeof WorkView !== 'undefined') {
      WorkView.render();
    } else if (tabName === 'family' && typeof FamilyView !== 'undefined') {
      FamilyView.render();
    } else if (tabName === 'notes' && typeof NotesView !== 'undefined') {
      NotesView.render();
    } else if (tabName === 'stats' && typeof StatsView !== 'undefined') {
      StatsView.render();
    } else if (tabName === 'dog' && typeof DogView !== 'undefined') {
      DogView.render();
    }
  }, 100);
};

// Открытие формы добавления
window.openQuickAdd = function() {
  const activeTab = document.querySelector('.nav-item.active');
  const tabName = activeTab ? activeTab.dataset.tab : 'calendar';
  
  if (tabName === 'calendar' || tabName === 'work') {
    if (typeof window.openWorkForm === 'function') {
      window.openWorkForm();
    } else {
      alert('Форма добавления записи');
    }
  } else if (tabName === 'family') {
    if (typeof window.openFamilyForm === 'function') {
      window.openFamilyForm();
    }
  } else if (tabName === 'notes') {
    if (typeof window.openNoteForm === 'function') {
      window.openNoteForm();
    }
  } else if (tabName === 'dog') {
    if (typeof window.openDogForm === 'function') {
      window.openDogForm();
    }
  }
};

// Настройка навигации
function setupNavigation() {
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', function() {
      const tabName = this.dataset.tab;
      window.switchTab(tabName);
    });
  });
}

// Инициализация
function initApp() {
  console.log(' Инициализация приложения...');
  
  // Проверяем наличие необходимых объектов
  if (typeof Storage === 'undefined') {
    console.error('Storage не найден!');
    return;
  }
  
  if (typeof Store === 'undefined') {
    console.error('Store не найден!');
    return;
  }
  
  // Настраиваем навигацию
  setupNavigation();
  
  // Открываем первую вкладку
  setTimeout(function() {
    window.switchTab('calendar');
    console.log(' Приложение готово!');
  }, 500);
}

// Запуск при загрузке
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initApp);
} else {
  initApp();
}

console.log(' app.js загружен');
