#!/bin/bash

# ==============================================
# Декомпиляция .jasper -> .jrxml
# Использование: ./preview.sh файл.jasper
# ==============================================

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка аргументов
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Ошибка: не указан .jasper файл${NC}"
    echo "Использование: $0 файл.jasper"
    exit 1
fi

INPUT_FILE="$1"
BASENAME=$(basename "$INPUT_FILE" .jasper)
OUTPUT_FILE="${BASENAME}.jrxml"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Проверка существования входного файла
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}❌ Ошибка: файл '$INPUT_FILE' не найден${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 Декомпиляция: $INPUT_FILE -> $OUTPUT_FILE${NC}"

# Создаём временную папку для Java-файла
TMP_DIR=$(mktemp -d)
JAVA_FILE="$TMP_DIR/JasperDecompiler.java"
CLASS_FILE="$TMP_DIR/JasperDecompiler.class"

cat > "$JAVA_FILE" << 'EOF'
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.engine.xml.JRXmlWriter;
import java.io.File;

public class JasperDecompiler {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Использование: java JasperDecompiler <input.jasper> <output.jrxml>");
            System.exit(1);
        }
        try {
            String inputFile = args[0];
            String outputFile = args[1];
            
            System.out.println("Загрузка: " + inputFile);
            JasperReport report = (JasperReport) JRLoader.loadObject(new File(inputFile));
            
            System.out.println("Запись: " + outputFile);
            JRXmlWriter.writeReport(report, outputFile, "UTF-8");
            
            System.out.println("✅ Готово!");
        } catch (Exception e) {
            System.err.println("❌ Ошибка:");
            e.printStackTrace();
            System.exit(1);
        }
    }
}
EOF

# Путь к библиотекам JasperStarter
JASPERSTARTER_HOME="/home/bequ1n/jasperstarter-3.6.2/jasperstarter"
LIB_DIR="$JASPERSTARTER_HOME/lib"

if [ ! -d "$LIB_DIR" ]; then
    echo -e "${RED}❌ Ошибка: папка с библиотеками не найдена: $LIB_DIR${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Собираем classpath из всех jar-файлов в lib
CLASSPATH=""
for jar in "$LIB_DIR"/*.jar; do
    if [ -z "$CLASSPATH" ]; then
        CLASSPATH="$jar"
    else
        CLASSPATH="$CLASSPATH:$jar"
    fi
done

# Компиляция
echo -e "${YELLOW}📦 Компиляция декомпилятора...${NC}"
javac -cp "$CLASSPATH" "$JAVA_FILE" 2> "$TMP_DIR/compile_error.log"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка компиляции Java-программы:${NC}"
    cat "$TMP_DIR/compile_error.log"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Запуск декомпиляции
echo -e "${YELLOW}🚀 Запуск декомпиляции...${NC}"
java -cp "$TMP_DIR:$CLASSPATH" JasperDecompiler "$INPUT_FILE" "$OUTPUT_FILE"

# Удаление временной папки
rm -rf "$TMP_DIR"

if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${GREEN}✅ Успешно: $OUTPUT_FILE создан${NC}"
    echo -e "${YELLOW}📄 Содержимое (первые 20 строк):${NC}"
    head -n 20 "$OUTPUT_FILE"
else
    echo -e "${RED}❌ Ошибка: выходной файл не создан${NC}"
    exit 1
fi
