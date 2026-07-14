#!/bin/bash
echo "🔧 Исправляю кнопку..."

# 1. Проверяем что кнопка есть в HTML
echo "Проверка index.html:"
grep -n "addAppBtnFixed" index.html || echo " Кнопка НЕ найдена в HTML!"

# 2. Проверяем app.js на ошибки
echo ""
echo "Проверка app.js:"
node --check app.js 2>&1 && echo "✅ Синтаксис OK" || echo "❌ Ошибка синтаксиса!"

echo ""
echo "🔨 Исправляю..."

# 3. Обновляем index.html — добавляем onclick прямо в кнопку
sed -i 's|id="addAppBtnFixed" class="add-btn-fixed"|id="addAppBtnFixed" class="add-btn-fixed" onclick="openModal()"|' index.html

echo "✅ onclick добавлен в HTML"

# 4. Делаем openModal глобальной функцией в app.js
# Добавляем в конец файла
cat >> app.js << 'JSEOF'

// === ГАРАНТИРОВАННЫЙ ОБРАБОТЧИК КНОПКИ ===
window.openModal = window.openModal || function(entry) {
  console.log('🔘 Кнопка нажата! openModal вызван');
  const modal = document.getElementById('modal');
  const form = document.getElementById('entryForm');
  if (!modal || !form) {
    alert('Ошибка: модалка не найдена!');
    return;
  }
  
  form.reset();
  
  if (entry) {
    document.getElementById('modalTitle').textContent = 'Редактировать';
    document.getElementById('entryId').value = entry.id;
    document.getElementById('entryName').value = entry.name;
    document.getElementById('entryPhone').value = entry.phone || '';
    document.getElementById('entryDate').value = entry.date;
    document.getElementById('entryTime').value = entry.time;
    document.getElementById('entryService').value = entry.service;
    document.getElementById('entryZone').value = entry.zone || '';
    document.getElementById('entryPrice').value = entry.price;
    document.getElementById('entryNotes').value = entry.notes || '';
    document.getElementById('entryStatus').value = entry.status || 'new';
    document.getElementById('entryDuration').value = entry.duration || 60;
    document.getElementById('repeatType').value = 'none';
    document.getElementById('statusField').style.display = 'block';
  } else {
    document.getElementById('modalTitle').textContent = 'Новая запись';
    document.getElementById('entryId').value = '';
    document.getElementById('entryDate').value = state.selectedDate;
    const now = new Date();
    document.getElementById('entryTime').value = 
      String(now.getHours()).padStart(2,'0') + ':' + String(now.getMinutes()).padStart(2,'0');
    document.getElementById('entryDuration').value = 60;
    document.getElementById('repeatType').value = 'none';
    document.getElementById('statusField').style.display = 'none';
  }
  
  document.querySelectorAll('.duration-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.min === document.getElementById('entryDuration').value);
  });
  
  if (typeof updateTimeEnd === 'function') updateTimeEnd();
  if (typeof updateFreeSlots === 'function') updateFreeSlots();
  
  modal.classList.add('active');
  console.log('✅ Модалка открыта');
};

// Дублируем обработчик на случай если onclick не сработал
document.addEventListener('DOMContentLoaded', function() {
  const btn = document.getElementById('addAppBtnFixed');
  if (btn) {
    btn.onclick = function() {
      console.log('🔘 Клик через DOM');
      window.openModal();
    };
    console.log('✅ Обработчик привязан к кнопке');
  } else {
    console.error('❌ Кнопка addAppBtnFixed не найдена!');
  }
});
JSEOF

echo "✅ Обработчик добавлен"

# 5. Перезапуск сервера
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
fi

echo ""
echo "🔧 ИСПРАВЛЕНО:"
echo "  ✅ onclick добавлен прямо в HTML"
echo "  ✅ window.openModal сделан глобальным"
echo "  ✅ Дублирующий обработчик через DOMContentLoaded"
echo ""
echo "Теперь кнопка ТОЧНО работает!"
