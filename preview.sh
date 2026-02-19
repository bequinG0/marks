
#!/bin/bash

# Создаём временный JSON-файл с параметрами
cat > /tmp/preview_params.json << EOF
{
    "code": "test",
    "name": "Трусы муж.",
    "composition": "100% хлопок",
    "color": "мультиколор",
    "size": "ONESIZE",
    "country": "Турция"
}
EOF

# Запускаем JasperStarter с правильными параметрами
jasperstarter process label.jasper \
    -o preview \
    -f pdf \
    -t json \
    --data-file /tmp/preview_params.json

# Открываем PDF (для Linux)
if [ -f preview.pdf ]; then
    xdg-open preview.pdf
    echo "✅ PDF создан и открыт"
else
    echo "❌ Ошибка: PDF не создан"
fi
