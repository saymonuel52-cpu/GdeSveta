# Автозапуск ГдеСвета

## Установка termux-boot

⚠️ **Важно:** termux-boot доступен только в F-Droid, НЕ в Google Play!

### Шаги:

1. **Установи F-Droid** (если нет):
   - Скачай с https://f-droid.org
   - Установи APK

2. **Установи termux-boot через F-Droid**:
   - Открой F-Droid
   - Найди "Termux:Boot"
   - Установи

3. **Включи автозапуск**:
   - Открой приложение "Termux:Boot" один раз
   - Разреши автозапуск в настройках Android

4. **Проверь**:
   - Перезагрузи телефон
   - Открой браузер
   - Перейди на http://localhost:8000

## Если не работает:

- Проверь что файл `~/.termux/boot/start-gdesveta.sh` существует
- Проверь права: `chmod +x ~/.termux/boot/start-gdesveta.sh`
- Смотри лог: `cat ~/GdeSvet/logs/boot.log`
