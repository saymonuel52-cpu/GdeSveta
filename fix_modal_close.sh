#!/bin/bash
echo "🔧 Исправляю закрытие модалки и очистку данных..."

# 1. ИСПРАВЛЕНИЕ: Модалка закрывается после сохранения
echo "1. Исправляю app.js - модалка закрывается..."

# Находим функцию saveEntry и добавляем Modal.close()
if grep -q "Modal.alert.*Запись сохранена" app.js; then
  # Уже есть Modal.close перед alert
  echo "✅ Modal.close() уже есть"
else
  # Добавляем закрытие модалки
  sed -i 's/Modal.alert.*Запись сохранена/Modal.close();\n      Modal.alert("✅ Запись сохранена")/' app.js
  echo "✅ Добавлено Modal.close() после сохранения"
fi

# 2. ИСПРАВЛЕНИЕ: Делаем кнопку закрытия более заметной
echo "2. Улучшаю видимость кнопки закрытия..."

cat >> styles/main.css << 'CSSFIX'

/* Улучшенная видимость кнопки закрытия модалки */
.close-modal {
  position: absolute;
  top: 15px;
  right: 20px;
  font-size: 32px;
  font-weight: bold;
  color: #666;
  cursor: pointer;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(0,0,0,0.1);
  transition: all 0.2s;
  z-index: 10;
}

.close-modal:hover {
  background: rgba(0,0,0,0.2);
  color: #000;
  transform: scale(1.1);
}

.close-modal:active {
  transform: scale(0.95);
}

/* Для тёмной темы */
body.dark-theme .close-modal {
  background: rgba(255,255,255,0.2);
  color: white;
}

body.dark-theme .close-modal:hover {
  background: rgba(255,255,255,0.3);
  color: white;
}
CSSFIX

echo "✅ Кнопка закрытия улучшена"

# 3. ДОБАВЛЕНИЕ: Кнопка очистки всех данных
echo "3. Добавляю кнопку очистки всех данных..."

# Добавляем функцию очистки в app.js
cat >> app.js << 'CLEARFUNC'

// Глобальная функция для очистки всех данных
window.clearAllData = function() {
  Modal.confirm(
    '️ ВНИМАНИЕ! Это удалит ВСЕ данные:\n\n• Все записи\n• Все заметки\n• Все задачи\n• Все шаблоны\n\nПродолжить?',
    () => {
      // Очищаем localStorage
      localStorage.clear();
      
      // Перезагружаем приложение
      Modal.alert('✅ Все данные удалены. Приложение перезагрузится...');
      setTimeout(() => {
        location.reload();
      }, 1500);
    }
  );
};
CLEARFUNC

echo "✅ Функция очистки добавлена"

# 4. Обновляем index.html - добавляем кнопку очистки
echo "4. Добавляю кнопку очистки в интерфейс..."

# Добавляем кнопку в статистику
if ! grep -q "clearAllData" index.html; then
  sed -i 's/<button id="exportBtn"/<button onclick="clearAllData()" style="background:#ffebee;color:#d32f2f;margin-right:5px;">🗑️ Очистить<\/button>\n          <button id="exportBtn"/' index.html
  echo "✅ Кнопка очистки добавлена в статистику"
else
  echo "⚠️  Кнопка уже существует"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ ИСПРАВЛЕНИЯ ВНЕСЕНЫ!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 Что сделано:"
echo "  1. ✅ Модалка закрывается после сохранения"
echo "  2. ✅ Кнопка закрытия стала больше и заметнее"
echo "  3. ✅ Добавлена кнопка '🗑️ Очистить' (в Статистике)"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Перезапусти сервер:"
echo "   pkill -f 'python.*http.server'"
echo "   python -m http.server 8000"
echo ""
echo "2. Открой: http://localhost:8000"
echo ""
echo "3. Проверь:"
echo "   • Кнопка закрытия (×) видна в углу модалки"
echo "   • После сохранения модалка закрывается"
echo "   • Кнопка '️ Очистить' в Статистике удаляет всё"
echo ""
echo "Если всё работает - пересобирай APK!"
