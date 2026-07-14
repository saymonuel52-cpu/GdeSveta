/**
 * NOTIFICATION SERVICE
 * С поддержкой тёмной темы
 */

const NotificationService = {
  permission: 'default',
  enabled: true,
  checkInterval: null,
  
  init() {
    if ('Notification' in window) {
      this.permission = Notification.permission;
    }
    this.startChecking();
    this.morningBriefing();
  },
  
  async requestPermission() {
    if (!('Notification' in window)) return false;
    try {
      const result = await Notification.requestPermission();
      this.permission = result;
      return result === 'granted';
    } catch (error) {
      console.error('[Notification] Error:', error);
      return false;
    }
  },
  
  show(title, options = {}) {
    this.showInApp(title, options.body || '');
    
    if (this.enabled && this.permission === 'granted' && 'Notification' in window) {
      try {
        new Notification(title, {
          body: options.body || '',
          icon: '/assets/icons/icon-192.png',
          badge: '/assets/icons/badge-72.png',
          tag: options.tag || 'gdesveta',
          requireInteraction: options.requireInteraction || false
        });
      } catch (error) {
        console.error('[Notification] Show error:', error);
      }
    }
  },
  
  showInApp(title, message) {
    const container = document.getElementById('notificationContainer');
    if (!container) return;
    
    const isDark = document.body.classList.contains('dark-theme');
    const notification = document.createElement('div');
    notification.className = 'in-app-notification';
    notification.style.cssText = isDark ? 
      'background: #2d3561; border-left-color: #ff8e53; color: #eaeaea;' : '';
    
    notification.innerHTML = `
      <div class="notification-content">
        <div class="notification-title" style="${isDark ? 'color: #eaeaea;' : ''}">${title}</div>
        <div class="notification-message" style="${isDark ? 'color: #aaa;' : ''}">${message}</div>
      </div>
      <button class="notification-close" onclick="this.parentElement.remove()" style="${isDark ? 'color: #aaa;' : ''}">×</button>
    `;
    
    container.appendChild(notification);
    setTimeout(() => { if (notification.parentElement) notification.remove(); }, 5000);
  },
  
  checkUpcoming() {
    const now = new Date();
    const upcoming = EntryService.getUpcoming(10);
    
    upcoming.forEach(entry => {
      const entryTime = new Date(entry.date + 'T' + entry.time);
      const diffMinutes = Math.floor((entryTime - now) / 60000);
      
      if (diffMinutes === 60) {
        this.show(`⏰ Скоро запись: ${entry.name}`, `${entry.time} — ${entry.service}`);
      }
      if (diffMinutes === 15) {
        this.show(`⏰ Через 15 минут: ${entry.name}`, `${entry.time} — ${entry.service}`);
      }
      if (diffMinutes === 5) {
        this.show(`⏰ Через 5 минут: ${entry.name}`, `${entry.time} — ${entry.service}`);
      }
    });
  },
  
  morningBriefing() {
    const today = Utils.getToday();
    const entries = EntryService.getByDate(today);
    const notes = NoteService.getByDate(today);
    
    if (entries.length === 0 && notes.length === 0) return;
    
    const workEntries = entries.filter(e => e.category === 'work');
    const familyEntries = entries.filter(e => e.category === 'family' || e.category === 'dog');
    
    let message = '';
    if (workEntries.length > 0) message += `💼 ${workEntries.length} клиента\n`;
    if (familyEntries.length > 0) message += `👨‍👩👧 ${familyEntries.length} семейных дел\n`;
    if (notes.length > 0) message += `📝 ${notes.length} заметок`;
    
    setTimeout(() => this.show('☀️ Доброе утро!', message), 1000);
  },
  
  startChecking() {
    this.checkInterval = setInterval(() => this.checkUpcoming(), 30000);
  },
  
  stopChecking() {
    if (this.checkInterval) clearInterval(this.checkInterval);
  },
  
  toggle(enabled) {
    this.enabled = enabled;
    Storage.set('notifications_enabled', enabled);
  },
  
  getStatus() {
    return {
      permission: this.permission,
      enabled: this.enabled,
      supported: 'Notification' in window
    };
  }
};

window.NotificationService = NotificationService;
