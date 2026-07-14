# 📱 СБОРКА APK ДЛЯ "ГДЕСВЕТА"

## 🎯 ВАРИАНТ 1: Онлайн-конвертер (САМЫЙ ПРОСТОЙ)

### WebIntoApp (рекомендую):

1. **Подготовь ZIP:**
```bash
   cd ~/GdeSvet
   zip -r gdesveta.zip \
     index.html \
     manifest.json \
     app.js \
     styles/ \
     src/ \
     icons/ \
     -x "*.bak" "logs/*"
```

2. **Загрузи на сайт:**
   - Открой https://www.webintoapp.com/
   - Нажми "Make App"
   - Загрузи `gdesveta.zip`
   - App Name: `GdeSveta`
   - Icon: загрузи `icons/icon-512.png`
   - Orientation: `Portrait`
   - Нажми "Build"

3. **Скачай APK:**
   - Подожди 2-3 минуты
   - Скачай готовый `GdeSveta.apk`
   - Установи на телефон

---

## 🎯 ВАРИАНТ 2: PWA Builder (официальный)

1. **Загрузи на GitHub:**
   - Создай репозиторий на GitHub
   - Загрузи все файлы проекта
   - Включи GitHub Pages

2. **Используй PWA Builder:**
   - Открой https://www.pwabuilder.com/
   - Введи URL твоего сайта (https://твой-ник.github.io/GdeSvet)
   - Нажми "Package for stores"
   - Выбери "Android"
   - Скачай APK

---

## 🎯 ВАРИАНТ 3: Локально через Capacitor (сложно)

```bash
cd ~/GdeSvet

# Установи Node.js (если нет)
pkg install nodejs

# Установи Capacitor
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android

# Инициализируй
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir=.

# Добавь Android
npx cap add android

# Синхронизируй
npx cap sync android

# Открой в Android Studio
npx cap open android

# В Android Studio:
# Build → Build APK
```

---

## 📋 ПРОВЕРКА ПЕРЕД СБОРКОЙ

✅ Все кнопки работают (удалить/копировать/статус)  
✅ Тёмная тема переключается  
✅ Календарь переключается между днями  
✅ Записи синхронизируются между вкладками  
✅ Прайс-лист работает  

---

##  ПОСЛЕ СБОРКИ

1. Установи APK на телефон
2. Разреши установку из неизвестных источников
3. Протестируй все функции
4. Напиши отзыв! 😊

---

**Удачи! 🎉**
