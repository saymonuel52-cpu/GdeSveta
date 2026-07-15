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
        html += '<div><div style="font-weight:600;color:#1e293b;margin-bottom:5px;">' + (entry.name || 'Клиент') + '</div>';
        html += '<div style="font-size:13px;color:#64748b;">⏰ ' + entry.time + ' • ' + entry.duration + ' мин' + (entry.service ? ' • ' + entry.service : '') + '</div></div>';
        if (entry.price) {
          html += '<div style="font-weight:700;color:#ff6b9d;">' + entry.price + '₽</div>';
        }
        html += '</div></div>';
      });
      html += '</div>';
    }
    
    html += '</div>';
    container.innerHTML = html;
    console.log('✅ WorkView отрисован, записей:', entries.length);
  }
};

window.WorkView = WorkView;
console.log('✅ WorkView загружен');
