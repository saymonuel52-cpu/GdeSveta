#!/bin/bash
echo "🔍 ДИАГНОСТИКА: Почему не работают кнопки"

# Создаём тестовую страницу
cat > test_buttons.html << 'TEST'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Тест кнопок</title>
  <style>
    body { font-family: sans-serif; padding: 20px; }
    button { padding: 10px 20px; margin: 5px; font-size: 16px; }
    .result { margin: 20px 0; padding: 15px; background: #f0f0f0; border-radius: 8px; }
  </style>
</head>
<body>
  <h1>🔍 Тест кнопок</h1>
  
  <div class="result" id="log">Лог действий:</div>
  
  <h2>Тест 1: Кнопка с onclick</h2>
  <button onclick="testFunction1()">Нажми меня (onclick)</button>
  
  <h2>Тест 2: Кнопка созданная через innerHTML</h2>
  <div id="dynamicButtons"></div>
  
  <h2>Тест 3: Глобальная функция</h2>
  <button onclick="globalTest()">Глобальная функция</button>
  
  <script>
    // Логирование
    function log(msg) {
      const logDiv = document.getElementById('log');
      logDiv.innerHTML += '<br>✅ ' + msg;
      console.log(msg);
    }
    
    // Тест 1
    function testFunction1() {
      log('testFunction1 вызвана!');
      alert('Работает!');
    }
    
    // Тест 2 - создаём кнопки динамически
    document.getElementById('dynamicButtons').innerHTML = `
      <button onclick="testFunction2()">Кнопка 2 (innerHTML)</button>
      <button onclick="window.testFunction3()">Кнопка 3 (window.)</button>
    `;
    
    function testFunction2() {
      log('testFunction2 вызвана!');
      alert('Работает!');
    }
    
    // Тест 3 - глобальная функция
    window.globalTest = function() {
      log('globalTest вызвана!');
      alert('Глобальная работает!');
    };
    
    window.testFunction3 = function() {
      log('testFunction3 вызвана!');
      alert('window. работает!');
    };
    
    log('Страница загружена');
  </script>
</body>
</html>
TEST

echo "✅ test_buttons.html создан"

# Открываем тест
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000/test_buttons.html"
  echo "✅ Тестовая страница открыта!"
fi

echo ""
echo "🔍 ПРОТЕСТИРУЙ:"
echo ""
echo "1. Нажми 'Нажми меня (onclick)' - должна появиться alert"
echo "2. Нажми 'Кнопка 2 (innerHTML)' - должна появиться alert"
echo "3. Нажми 'Кнопка 3 (window.)' - должна появиться alert"
echo "4. Нажми 'Глобальная функция' - должна появиться alert"
echo ""
echo "Напиши какие кнопки сработали, а какие нет!"
echo "Это поможет понять почему не работают кнопки в основном приложении."
