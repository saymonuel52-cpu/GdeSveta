#!/bin/bash
echo "🔧 Исправляю модальное окно..."

# 1. Резервная копия
cp style.css style.css.backup.modal.$(date +%s)
cp index.html index.html.backup.modal.$(date +%s)
echo "💾 Бэкап создан"

# 2. Обновляем стили модалки в style.css
# Удаляем старые стили модалки и добавляем новые
sed -i '/\/\* === СТАТУСЫ ЗАПИСЕЙ === \*\//,$d' style.css

cat >> style.css << 'CSS'

/* === СТАТУСЫ ЗАПИСЕЙ === */
.entry-card.status-new { border-left-color: #2196f3; }
.entry-card.status-confirmed { border-left-color: #4caf50; }
.entry-card.status-done { border-left-color: #9e9e9e; opacity: 0.7; }
.entry-card.status-cancelled { border-left-color: #f44336; opacity: 0.5; text-decoration: line-through; }

.status-badge {
  display: inline-block; padding: 3px 8px; border-radius: 10px;
  font-size: 11px; font-weight: bold; margin-left: 8px;
}
.status-new { background: #e3f2fd; color: #1976d2; }
.status-confirmed { background: #e8f5e9; color: #388e3c; }
.status-done { background: #f5f5f5; color: #616161; }
.status-cancelled { background: #ffebee; color: #d32f2f; }

.status-buttons { display: flex; gap: 4px; margin-top: 8px; flex-wrap: wrap; }
.status-btn {
  flex: 1; min-width: 70px; padding: 6px; border: 1px solid #ddd;
  border-radius: 6px; font-size: 11px; background: white; cursor: pointer;
  transition: all 0.2s;
}
.status-btn.active { background: #ff6b9d; color: white; border-color: #ff6b9d; }

/* === ДЛИТЕЛЬНОСТЬ === */
.duration-row { display: flex; gap: 5px; flex-wrap: wrap; margin-top: 5px; }
.duration-btn {
  padding: 8px 12px; border: 1px solid #ddd; border-radius: 6px;
  background: white; cursor: pointer; font-size: 13px;
}
.duration-btn.active { background: #ff6b9d; color: white; border-color: #ff6b9d; }

.time-end-info {
  background: #fff3e0; padding: 8px 12px; border-radius: 8px;
  font-size: 13px; color: #e65100; margin-top: 8px;
}

/* === СВОБОДНЫЕ СЛОТЫ === */
.free-slots {
  background: #e8f5e9; padding: 10px; border-radius: 8px;
  margin-top: 10px; font-size: 13px;
}
.free-slots-title { font-weight: bold; color: #388e3c; margin-bottom: 5px; }
.free-slot-btn {
  display: inline-block; padding: 5px 10px; margin: 2px;
  background: white; border: 1px solid #4caf50; border-radius: 15px;
  color: #388e3c; font-size: 12px; cursor: pointer;
}

/* === КОНФЛИКТ === */
.conflict-warning {
  background: #ffebee; border-left: 4px solid #f44336;
  padding: 10px; border-radius: 6px; margin-top: 10px;
  color: #c62828; font-size: 13px;
}

/* === МОДАЛКА (ПОЛНОЭКРАННАЯ) === */
.modal {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 10000;
  align-items: flex-end;
  justify-content: center;
}
.modal.active {
  display: flex;
}
.modal-content {
  background: white;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  border-radius: 20px 20px 0 0;
  padding: 20px;
  overflow-y: auto;
  position: relative;
  animation: slideUp 0.3s ease;
}
@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}
.close-modal {
  position: absolute;
  top: 15px;
  right: 20px;
  font-size: 32px;
  cursor: pointer;
  color: #999;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #f5f5f5;
}
.close-modal:hover { background: #e0e0e0; }
.modal-content h3 {
  margin-bottom: 15px;
  color: #333;
  font-size: 20px;
  padding-right: 40px;
}
.modal-content label {
  display: block;
  margin: 12px 0 5px;
  font-size: 14px;
  color: #666;
  font-weight: 500;
}
.modal-content input,
.modal-content select,
.modal-content textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 10px;
  font-size: 15px;
  font-family: inherit;
  background: #fafafa;
}
.modal-content input:focus,
.modal-content select:focus,
.modal-content textarea:focus {
  outline: none;
  border-color: #ff6b9d;
  background: white;
}
.time-row { display: flex; gap: 5px; align-items: center; }
.time-row input { flex: 1; }
.quick-time {
  padding: 10px 12px;
  background: #f0f0f0;
  border: none;
  border-radius: 8px;
  font-size: 12px;
  cursor: pointer;
}
.quick-time:active { background: #e0e0e0; }
.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
  padding-bottom: 20px;
}
.save-btn {
  flex: 2;
  padding: 14px;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: bold;
  font-size: 16px;
  cursor: pointer;
}
.save-btn:active { opacity: 0.8; }
.cancel-btn {
  flex: 1;
  padding: 14px;
  background: #f0f0f0;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  cursor: pointer;
}
CSS
echo "✅ Стили модалки обновлены"

# 3. Перезапуск сервера
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

# 4. Открываем браузер
if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "🌐 Браузер открыт!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "✅ МОДАЛКА ИСПРАВЛЕНА!"
echo "✨ Теперь модалка выезжает снизу (как в нативных приложениях)"
echo "✨ Закрывается по крестику или клику на фон"
