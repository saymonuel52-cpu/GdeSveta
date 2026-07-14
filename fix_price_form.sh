#!/bin/bash
echo "🔧 Улучшаю форму добавления услуг в прайс"

# Обновляем app.js — заменяем addPriceItem на модальную форму
cat > temp_patch.js << 'PATCH'

// === УЛУЧШЕННАЯ ФОРМА ДОБАВЛЕНИЯ УСЛУГИ ===
window.addPriceItem = function() {
  const content = `
    <form id="priceForm" onsubmit="return savePriceItem(event)">
      <label>Название услуги *</label>
      <input type="text" id="priceName" required placeholder="Напр. Ноги до колен" 
             style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
      
      <label>Тип услуги</label>
      <select id="priceType" style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
        <option value="Шугаринг">💅 Шугаринг</option>
        <option value="LPG-массаж">💆 LPG-массаж</option>
        <option value="Другое">📌 Другое</option>
      </select>
      
      <label>Длительность (минуты)</label>
      <select id="priceDuration" required style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
        <option value="10">⏱️ 10 минут</option>
        <option value="15">⏱️ 15 минут</option>
        <option value="20">⏱️ 20 минут</option>
        <option value="30" selected>⏱️ 30 минут (полчаса)</option>
        <option value="45">⏱️ 45 минут</option>
        <option value="60">⏱️ 1 час</option>
        <option value="90">️ 1.5 часа</option>
        <option value="120">⏱️ 2 часа</option>
      </select>
      
      <label>Цена (₽) *</label>
      <input type="number" id="priceValue" required placeholder="Напр. 1500" min="0"
             style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
      
      <div style="background:#fff3e0;padding:12px;border-radius:8px;margin-bottom:15px;font-size:13px;">
        💡 <b>Совет:</b> Укажи реальную цену и время для точного планирования
      </div>
      
      <div class="form-actions">
        <button type="submit" class="save-btn" style="flex:1;">💾 Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()" style="flex:1;">Отмена</button>
      </div>
    </form>
  `;
  
  Modal.form({ title: '💰 Добавить услугу в прайс', content });
};

// Функция сохранения
window.savePriceItem = function(e) {
  e.preventDefault();
  
  const name = document.getElementById('priceName').value;
  const type = document.getElementById('priceType').value;
  const duration = parseInt(document.getElementById('priceDuration').value);
  const price = parseInt(document.getElementById('priceValue').value);
  
  try {
    PriceService.create({ name, service: type, duration, price });
    Modal.close();
    Modal.alert(`✅ Услуга "${name}" добавлена в прайс!\n\n⏱️ ${duration} мин\n💰 ${price}₽`);
    setTimeout(() => {
      if (typeof showPriceList === 'function') showPriceList();
    }, 500);
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
  
  return false;
};
PATCH

# Добавляем патч в app.js
cat temp_patch.js >> app.js
rm temp_patch.js

echo "✅ Форма улучшена!"

# Пересобираем www
rm -rf www
mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ www/

# Пересобираем APK
cd android
./gradlew assembleDebug

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../gdesveta-v3.apk
  cd ..
  cp gdesveta-v3.apk ~/storage/downloads/GdeSveta_v3.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════"
  echo "🎉 ВЕРСИЯ v3 С УЛУЧШЕННОЙ ФОРМОЙ!"
  echo "═══════════════════════════════════════"
  echo ""
  echo "📁 Файл: ~/GdeSvet/gdesveta-v3.apk"
  echo "📥 Или: ~/storage/downloads/GdeSveta_v3.apk"
  echo ""
  echo "✨ ЧТО УЛУЧШЕНО:"
  echo "  1. ✅ Выбор длительности из списка (10/15/20/30/45/60/90/120 мин)"
  echo "  2. ✅ Выпадающий список типов услуг"
  echo "  3. ✅ Подсказки и примеры в полях"
  echo "  4. ✅ Красивая форма вместо prompt()"
  echo "  5. ✅ Валидация (нельзя ввести отрицательную цену)"
  echo ""
  echo "Удали v2 и установи v3!"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
