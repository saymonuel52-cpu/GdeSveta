#!/bin/bash
echo "🔧 ИСПРАВЛЯЮ КНОПКУ СОХРАНЕНИЯ..."

# 1. Проверяем и исправляем функцию сохранения в app.js
cat >> app.js << 'FIXSAVE'

// === ИСПРАВЛЕНИЕ КНОПКИ СОХРАНЕНИЯ ===

// Глобальная функция сохранения записей
window.saveEntryFromForm = function() {
  console.log('💾 saveEntryFromForm вызвана!');
  
  try {
    const name = document.getElementById('clientName').value.trim();
    const phone = document.getElementById('clientPhone').value.trim();
    const date = document.getElementById('entryDate').value;
    const time = document.getElementById('entryTime').value;
    const duration = parseInt(document.getElementById('entryDuration').value) || 60;
    const price = parseInt(document.getElementById('entryPrice').value) || 0;
    const notes = document.getElementById('entryNotes').value.trim();
    const service = document.getElementById('serviceType')?.value || 'Другое';
    const zone = document.getElementById('serviceZone')?.value || '';
    const status = document.getElementById('entryStatus')?.value || 'new';
    
    console.log('📝 Данные формы:', { name, date, time, duration, price });
    
    // Валидация
    if (!name) {
      Modal.alert('❌ Введите имя клиента!');
      return false;
    }
    
    if (!date) {
      Modal.alert('❌ Выберите дату!');
      return false;
    }
    
    if (!time) {
      Modal.alert('❌ Выберите время!');
      return false;
    }
    
    // Создаём запись
    const entryData = {
      category: 'work',
      name,
      phone,
      date,
      time,
      duration,
      price,
      notes,
      service,
      zone,
      status,
      createdAt: new Date().toISOString()
    };
    
    console.log('✅ Создаём запись:', entryData);
    
    // Проверяем EntryService
    if (typeof EntryService === 'undefined') {
      console.error('❌ EntryService не найден!');
      Modal.alert('❌ Ошибка: EntryService не загружен!');
      return false;
    }
    
    // Сохраняем
    EntryService.create(entryData);
    
    console.log('✅ Запись сохранена!');
    
    // Закрываем форму
    Modal.close();
    
    // Показываем уведомление
    Modal.alert(`✅ Запись сохранена!\n\n${name}\n${date} в ${time}\n${duration} мин, ${price}₽`);
    
    // Обновляем виды
    setTimeout(() => {
      if (typeof CalendarView !== 'undefined') CalendarView.render();
      if (typeof WorkView !== 'undefined') WorkView.render();
      if (typeof refreshAllViews === 'function') refreshAllViews();
    }, 300);
    
    return true;
    
  } catch (error) {
    console.error('❌ Ошибка сохранения:', error);
    Modal.alert('❌ Ошибка: ' + error.message);
    return false;
  }
};

console.log('✅ saveEntryFromForm загружена');
FIXSAVE

echo "✅ Функция сохранения добавлена"

# 2. Исправляем форму добавления записей - добавляем явный обработчик
cat > fix_form_handler.js << 'FIXFORM'

// Переопределяем openWorkForm чтобы добавить правильный обработчик
const _origOpenWorkForm = window.openWorkForm;
window.openWorkForm = function(id = null) {
  if (_origOpenWorkForm) _origOpenWorkForm(id);
  
  // После открытия формы добавляем обработчик на кнопку сохранения
  setTimeout(() => {
    const saveBtn = document.querySelector('button[onclick*="saveEntryFromForm"]') || 
                    Array.from(document.querySelectorAll('button')).find(b => 
                      b.textContent.includes('Сохранить') && !b.textContent.includes('Отмена')
                    );
    
    if (saveBtn) {
      console.log('🔧 Найден кнопка Сохранить, добавляем обработчик');
      saveBtn.onclick = function(e) {
        e.preventDefault();
        console.log(' Кнопка Сохранить нажата!');
        saveEntryFromForm();
      };
    } else {
      console.warn('⚠️ Кнопка Сохранить не найдена');
    }
  }, 200);
};

console.log('✅ Обработчик формы исправлен');
FIXFORM

cat fix_form_handler.js >> app.js
rm fix_form_handler.js

echo "✅ Обработчик формы добавлен"

# 3. Добавляем отладочную информацию
cat >> app.js << 'DEBUG'

// Отладка: проверяем все функции при загрузке
window.checkAppFunctions = function() {
  console.log('🔍 Проверка функций приложения:');
  console.log('  EntryService:', typeof EntryService);
  console.log('  EntryService.create:', typeof EntryService?.create);
  console.log('  Store:', typeof Store);
  console.log('  Store.addEntry:', typeof Store?.addEntry);
  console.log('  saveEntryFromForm:', typeof window.saveEntryFromForm);
  console.log('  Modal:', typeof Modal);
  console.log('  Modal.close:', typeof Modal?.close);
  console.log('  CalendarView:', typeof CalendarView);
  console.log('  WorkView:', typeof WorkView);
};

// Запускаем проверку при загрузке
setTimeout(() => {
  console.log(' Приложение загружено');
  if (typeof checkAppFunctions === 'function') checkAppFunctions();
}, 1000);

console.log('✅ Отладочные функции загружены');
DEBUG

echo "✅ Отладка добавлена"

# Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "fix: Исправлена кнопка сохранения записей"
git push origin main

echo "📦 Сборка APK..."
rm -rf android www
mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ www/

npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir="www" > /dev/null 2>&1
npx cap add android > /dev/null 2>&1
npx cap sync android > /dev/null 2>&1

cd android
chmod +x gradlew
./gradlew assembleDebug > /dev/null 2>&1

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_SaveFixed.apk
  cd ..
  cp GdeSveta_SaveFixed.apk ~/storage/downloads/GdeSveta_SaveFixed.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ КНОПКА СОХРАНЕНИЯ ИСПРАВЛЕНА!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_SaveFixed.apk"
  echo ""
  echo "🔧 ЧТО ИСПРАВЛЕНО:"
  echo "• Добавлена глобальная функция saveEntryFromForm()"
  echo "• Явный обработчик на кнопку 'Сохранить'"
  echo "• Валидация обязательных полей"
  echo "• Визуальное подтверждение после сохранения"
  echo "• Автоматическое обновление календаря"
  echo "• Отладочная информация в консоли"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_SaveFixed.apk"
  echo "2. Нажми '+ Добавить'"
  echo "3. Заполни: Имя='Тест', Дата, Время, Цена"
  echo "4. Нажми 'Сохранить'"
  echo "5. Должно появиться: '✅ Запись сохранена!'"
  echo "6. Запись появится в календаре"
  echo ""
  echo "🔍 ЕСЛИ ВСЁ ЕЩЁ НЕ РАБОТАЕТ:"
  echo "Открой браузер, нажми F12 (консоль)"
  echo "Выполни: checkAppFunctions()"
  echo "Пришли скриншот консоли"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
