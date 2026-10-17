#!/bin/bash

LOG_DIR="$1"
THRESHOLD="${2:-70}"
BACKUP_DIR="${3:-$HOME/lab1/backup}"

if [ -z "$LOG_DIR" ]; then
echo "укажите путь к папке"
echo "шпаргалка: $0 <папка> [порог] <папка_бэкапа>"
exit 1
fi

if [ ! -d "$LOG_DIR" ]; then
echo "папка '$LOG_DIR' не найдена"
exit 1
fi

mkdir -p "$BACKUP_DIR"

USAGE=$(df -P "$LOG_DIR" | tail -n 1 | awk '{print int($5)}' | tr -d '%')

echo "папка: $LOG_DIR"
echo "заполнено: ${USAGE} % (порог ${THRESHOLD} %)"

if [ "$USAGE" -le "$THRESHOLD" ]; then
echo "чистка не требуется"
exit 0 
fi

if [ "${LAB1_MAX_COMPRESSION:-0}" = "1" ]; then
TAR_FLAG="--lzma"
EXT="tar.xz"
echo "сжатие lzma"
else
TAR_FLAG="-z"
EXT="tar.gz"
echo "сжатие gzip"
fi

while [ "$USAGE" -gt "$THRESHOLD" ]; do
OLDEST=$(find "$LOG_DIR" -maxdepth 1 -type f -printf '%T@ %p\n' | sort -n | head -n 1 | cut -d' ' -f2- )

if [ -z "$OLDEST" ]; then
echo "файлов больше нет"
break
fi

FILE_NAME=$(basename "$OLDEST")
TIMES=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="$BACKUP_DIR/${FILE_NAME}_${TIMES}.${EXT}"

echo "архивируем: $FILE_NAME"
tar $TAR_FLAG -cf "$ARCHIVE_NAME" -C "$LOG_DIR" "$FILE_NAME"
rm -f "$OLDEST"

USAGE=$(df -P "$LOG_DIR" | tail -n 1 | awk '{print int($5)}' | tr -d '%')

done

echo "новый процент: ${USAGE} %"
