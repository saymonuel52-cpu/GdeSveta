const WorkView = {
  render: function() {
    const container = document.getElementById('workView');
    if (!container) return;
    
    const entries = Store.getEntries().filter(e => e.category === 'work');
    
    let html = '<div style="padding:20px;">';
    html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">';
    html += '<h3 style="margin:0;color:#1e293b;">💼 Работа</h3>';
    html += '<button onclick="openWorkForm()" style="padding:10px 20px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:600;cursor:pointer;">+ Добавить</button>';
    html += '</div>';
    
    if (entries.length === 0) {
      html += '<div style="background:#f8fafc;padding:40px;border-radius:16px;text-align:center;">';
      html += '<p style="color:#94a3b8;margin:0;">Нет записей</p>';
      html += '<button onclick="openWorkForm()" style="margin-top:15px;padding:12px 30px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:600;cursor:pointer;">+ Добавить первую запись</button>';
      html += '</div>';
    } else {
      html += '<div style="display:flex;flex-direction:column;gap:12px;">';
      entries.forEach(entry => {
        html += '<div style="background:white;padding:16px;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);border-left:4px solid #ff6b9d;">';
        html += '<div style="display:flex;justify-content:space-between;align-items:center;">';
        html += '<div style="flex:1;">';
        html += '<div style="font-weight:600;color:#1e293b;margin-bottom:5px;">' + (entry.name || 'Клиент') + '</div>';
        html += '<div style="font-size:13px;color:#64748b;">📅 ' + entry.date + ' • ⏰ ' + entry.time + ' • ' + entry.duration + ' мин</div>';
        if (entry.service) {
          html += '<div style="font-size:13px;color:#64748b;margin-top:3px;">💅 ' + entry.service + '</div>';
        }
        html += '</div>';
        if (entry.price) {
          html += '<div style="font-weight:700;color:#ff6b9d;font-size:18px;">' + entry.price + '₽</div>';
        }
        html += '</div>';
        html += '<div style="display:flex;gap:8px;margin-top:12px;">';
        html += '<button onclick="openWorkForm(' + entry.id + ')" style="padding:6px 12px;background:#3b82f6;color:white;border:none;border-radius:8px;font-size:13px;cursor:pointer;">✏️ Изменить</button>';
        html += '<button onclick="deleteEntry(' + entry.id + ')" style="padding:6px 12px;background:#ef4444;color:white;border:none;border-radius:8px;font-size:13px;cursor:pointer;">🗑️ Удалить</button>';
        html += '</div>';
        html += '</div>';
      });
      html += '</div>';
    }
    
    html += '</div>';
    container.innerHTML = html;
    console.log('✅ WorkView отрисован, записей:', entries.length);
  }
};

window.WorkView = WorkView;

// Удаление записи
window.deleteEntry = function(id) {
  if (confirm('Удалить эту запись?')) {
    Store.deleteEntry(id);
    WorkView.render();
    console.log('✅ Запись удалена:', id);
  }
};

console.log('✅ WorkView загружен');
