#!/bin/bash
echo "✏️ ДОБАВЛЯЮ РЕДАКТИРОВАНИЕ ЧЛЕНОВ СЕМЬИ..."

# 1. Добавляем функции редактирования в app.js
cat >> app.js << 'FAMILYEDIT'

// === РЕДАКТИРОВАНИЕ ЧЛЕНОВ СЕМЬИ ===

// Открыть форму редактирования члена семьи
window.editFamilyMember = function(id) {
  console.log('️ editFamilyMember:', id);
  const member = Store.getFamilyMembers().find(m => m.id === id);
  if (!member) {
    Modal.alert('❌ Член семьи не найден!');
    return;
  }
  
  const roles = [
    { value: 'Сын', label: ' Сын' },
    { value: 'Дочь', label: '👧 Дочь' },
    { value: 'Муж', label: '👨 Муж' },
    { value: 'Жена', label: '👩 Жена' },
    { value: 'Другое', label: '👤 Другое' }
  ];
  
  const roleOptions = roles.map(r => 
    `<option value="${r.value}" ${member.role === r.value ? 'selected' : ''}>${r.label}</option>`
  ).join('');
  
  const content = `
    <form id="familyEditForm" onsubmit="return saveFamilyMemberEdit(event, ${id})">
      <label>👤 Имя</label>
      <input type="text" id="editMemberName" value="${member.name || ''}" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label>🎭 Роль в семье</label>
      <select id="editMemberRole" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        ${roleOptions}
      </select>
      
      <label>🏫 Школа / Садик / Работа</label>
      <input type="text" id="editMemberSchool" value="${member.school || member.place || ''}"
        placeholder="Напр. Школа №5, 3 класс"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label>🎂 Возраст</label>
      <input type="number" id="editMemberAge" value="${member.age || ''}" min="0" max="100"
        placeholder="Напр. 8"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label>🎨 Кружки / Секции</label>
      <textarea id="editMemberCircles" rows="2"
        placeholder="Напр. Танцы (вт, чт), Плавание (сб)"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">${member.circles || ''}</textarea>
      
      <label>💬 Примечания</label>
      <textarea id="editMemberNotes" rows="2"
        placeholder="Напр. Аллергия на орехи, любит рисовать"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">${member.notes || ''}</textarea>
      
      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit"
          style="flex:1;padding:15px;background:linear-gradient(135deg,#3b82f6,#60a5fa);color:white;border:none;border-radius:12px;font-weight:700;cursor:pointer;box-shadow:0 4px 12px rgba(59,130,246,0.4);">
          💾 Сохранить изменения
        </button>
        <button type="button" onclick="Modal.close()"
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;
  
  Modal.form({ title: '✏️ Редактировать члена семьи', content });
};

// Сохранить изменения члена семьи
window.saveFamilyMemberEdit = function(e, id) {
  e.preventDefault();
  console.log('💾 saveFamilyMemberEdit:', id);
  
  const members = Store.getFamilyMembers();
  const index = members.findIndex(m => m.id === id);
  
  if (index === -1) {
    Modal.alert('❌ Член семьи не найден!');
    return false;
  }
  
  members[index] = {
    ...members[index],
    name: document.getElementById('editMemberName').value,
    role: document.getElementById('editMemberRole').value,
    school: document.getElementById('editMemberSchool').value,
    place: document.getElementById('editMemberSchool').value,
    age: parseInt(document.getElementById('editMemberAge').value) || null,
    circles: document.getElementById('editMemberCircles').value,
    notes: document.getElementById('editMemberNotes').value,
    updatedAt: new Date().toISOString()
  };
  
  Storage.set('familyMembers', JSON.stringify(members));
  Modal.close();
  Modal.alert('✅ Изменения сохранены!');
  
  setTimeout(() => {
    if (typeof FamilyView !== 'undefined') FamilyView.render();
    if (typeof showFamilyMembers === 'function') showFamilyMembers();
  }, 200);
  
  return false;
};

// Улучшенный рендеринг карточки члена семьи с кнопкой редактирования
window.renderFamilyMemberCard = function(member) {
  const roleEmojis = {
    'Сын': '👦',
    'Дочь': '👧',
    'Муж': '👨',
    'Жена': '👩',
    'Другое': '👤'
  };
  const emoji = roleEmojis[member.role] || '👤';
  
  return `
    <div class="family-member-card" style="background:white;border-radius:16px;padding:15px;margin:10px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1);border-left:4px solid #3b82f6;">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
        <div style="display:flex;align-items:center;gap:10px;">
          <span style="font-size:32px;">${emoji}</span>
          <div>
            <div style="font-weight:700;font-size:18px;color:#1e293b;">${member.name || 'Без имени'}</div>
            <div style="font-size:13px;color:#64748b;">${member.role || 'Член семьи'}${member.age ? ' · ' + member.age + ' лет' : ''}</div>
          </div>
        </div>
        <div style="display:flex;gap:5px;">
          <button onclick="editFamilyMember(${member.id})" 
            style="background:#3b82f6;color:white;border:none;border-radius:8px;padding:8px 12px;font-size:13px;cursor:pointer;font-weight:600;">
            ✏️
          </button>
          <button onclick="deleteFamilyMember(${member.id})" 
            style="background:#ef4444;color:white;border:none;border-radius:8px;padding:8px 12px;font-size:13px;cursor:pointer;font-weight:600;">
            🗑️
          </button>
        </div>
      </div>
      ${member.school ? `<div style="font-size:14px;color:#334155;margin:5px 0;">🏫 ${member.school}</div>` : ''}
      ${member.circles ? `<div style="font-size:14px;color:#334155;margin:5px 0;"> ${member.circles}</div>` : ''}
      ${member.notes ? `<div style="font-size:13px;color:#64748b;margin-top:8px;font-style:italic;">💬 ${member.notes}</div>` : ''}
    </div>
  `;
};

console.log('✅ Функции редактирования семьи загружены');
FAMILYEDIT

echo "✅ Функции редактирования добавлены"

# 2. Обновляем FamilyView чтобы использовал новые карточки
cat > src/views/FamilyView.js << 'FAMILYVIEW'
/**
 * FAMILY VIEW v3.0
 * С редактированием и красивыми карточками
 */

const FamilyView = {
  container: null,
  filter: 'all',
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    let members = Store.getFamilyMembers() || [];
    
    // Фильтрация по роли
    if (this.filter !== 'all') {
      const roleMap = {
        school: ['Сын', 'Дочь'],
        circles: ['Сын', 'Дочь'],
        doctor: ['Сын', 'Дочь', 'Муж', 'Жена'],
        dog: []
      };
      const allowed = roleMap[this.filter] || [];
      if (allowed.length > 0) {
        members = members.filter(m => allowed.includes(m.role));
      }
    }
    
    let html = `
      <div class="family-filters">
        <button class="family-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">Все</button>
        <button class="family-filter ${this.filter === 'school' ? 'active' : ''}" data-filter="school"> Школа</button>
        <button class="family-filter ${this.filter === 'circles' ? 'active' : ''}" data-filter="circles"> Кружки</button>
        <button class="family-filter ${this.filter === 'doctor' ? 'active' : ''}" data-filter="doctor"> Врачи</button>
        <button class="family-filter ${this.filter === 'dog' ? 'active' : ''}" data-filter="dog">🐕 Собака</button>
      </div>
    `;
    
    if (members.length === 0) {
      html += '<div class="empty-state">Нет членов семьи</div>';
    } else {
      members.forEach(member => {
        if (typeof renderFamilyMemberCard === 'function') {
          html += renderFamilyMemberCard(member);
        } else {
          html += `<div style="padding:15px;background:white;border-radius:12px;margin:10px 0;">
            <b>${member.name}</b> - ${member.role || ''}
            <button onclick="editFamilyMember(${member.id})" style="margin-left:10px;">✏️</button>
          </div>`;
        }
      });
    }
    
    this.container.innerHTML = html;
    
    // Обработчики фильтров
    this.container.querySelectorAll('.family-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
  },
  
  setupListeners() {
    Events.on('family:updated', () => this.render());
  }
};

window.FamilyView = FamilyView;
console.log('✅ FamilyView v3.0 загружен');
FAMILYVIEW

echo "✅ FamilyView обновлён"

# 3. Добавляем функцию удаления члена семьи (если её нет)
cat >> app.js << 'DELETEMEMBER'

// Удаление члена семьи
window.deleteFamilyMember = function(id) {
  Modal.confirm('Удалить этого члена семьи?', () => {
    const members = Store.getFamilyMembers();
    const filtered = members.filter(m => m.id !== id);
    Storage.set('familyMembers', JSON.stringify(filtered));
    Modal.close();
    Modal.alert('✅ Член семьи удалён!');
    setTimeout(() => {
      if (typeof FamilyView !== 'undefined') FamilyView.render();
      if (typeof showFamilyMembers === 'function') showFamilyMembers();
    }, 200);
  });
};
DELETEMEMBER

echo "✅ Функция удаления добавлена"

# 4. Добавляем стили
cat >> styles/main.css << 'FAMILYSTYLES'

/* Карточки членов семьи */
.family-member-card {
  transition: all 0.3s ease;
  animation: fadeInUp 0.4s ease;
}

.family-member-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.15) !important;
}

.family-member-card button {
  transition: all 0.2s;
}

.family-member-card button:hover {
  transform: scale(1.1);
}

/* Кнопки действий в карточке */
.family-member-card button {
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

/* Анимация появления */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
FAMILYSTYLES

echo "✅ Стили добавлены"

# 5. Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлено редактирование членов семьи с красивыми карточками"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_FamilyEdit.apk
  cd ..
  cp GdeSveta_FamilyEdit.apk ~/storage/downloads/GdeSveta_FamilyEdit.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✏️ РЕДАКТИРОВАНИЕ СЕМЬИ ГОТОВО!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_FamilyEdit.apk"
  echo ""
  echo "✅ ЧТО ДОБАВЛЕНО:"
  echo "• Кнопка ✏️ на каждой карточке члена семьи"
  echo "• Форма редактирования с полями:"
  echo "  - Имя"
  echo "  - Роль (Сын/Дочь/Муж/Жена)"
  echo "  - Школа/Садик/Работа"
  echo "  - Возраст"
  echo "  - Кружки/Секции"
  echo "  - Примечания"
  echo "• Красивые карточки с эмодзи-аватарами"
  echo "• Анимация при наведении"
  echo "• Кнопка 🗑️ для удаления"
  echo ""
  echo " ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_FamilyEdit.apk"
  echo "2. Открой вкладку 'Семья'"
  echo "3. Нажми '👥 Семья' — увидишь список"
  echo "4. Добавь члена семьи (если нет)"
  echo "5. Нажми ️ на карточке — откроется форма"
  echo "6. Измени данные и сохрани"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
