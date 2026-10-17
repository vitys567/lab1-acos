#!/bin/bash

SCRIPT="./cleanup.sh"
TEST_DIR="$HOME/lab1/test_log"
BACKUP_DIR="$HOME/lab1/test_backup"
DISK_IMG="$HOME/lab1/disk.img"

create_file() {
local name="$1" size_mb="$2" age_days="$3"
dd if=/dev/zero of="$TEST_DIR/$name" bs=1M count="$size_mb" status=none
touch -d "$age_days days ago" "$TEST_DIR/$name"
}

clean_env() {
sudo umount "$TEST_DIR" 2>/dev/null
rm -rf "$TEST_DIR" "$BACKUP_DIR" "$DISK_IMG"
mkdir -p "$TEST_DIR" "$BACKUP_DIR"
echo "создание виртуального диска 1 ГБ..."
dd if=/dev/zero of="$DISK_IMG" bs=1M count=1024 status=none
mkfs.ext4 -q -F "$DISK_IMG"
sudo mount -o loop "$DISK_IMG" "$TEST_DIR"
}

echo "ТЕСТ 1: превышение порога"
clean_env
create_file "old_1.log" 200 5
create_file "old_2.log" 200 4
create_file "old_3.log" 200 3
create_file "new_1.log" 150 1
create_file "new_2.log" 150 1

"$SCRIPT" "$TEST_DIR" 50 "$BACKUP_DIR"

if [ -f "$TEST_DIR/old_1.log" ]; then
echo "ТЕСТ 1 ПРОВАЛЕН"
else
echo "ТЕСТ 1 ПРОЙДЕН: старые файлы удалены"
fi

if ls "$BACKUP_DIR"/*.tar.gz >/dev/null 2>&1; then
echo "Архив .tar.gz создан"
fi

echo "ТЕСТ 2: lzma"
clean_env
create_file "old_1.log" 400 5
create_file "new_1.log" 200 1
LAB1_MAX_COMPRESSION=1 "$SCRIPT" "$TEST_DIR" 40 "$BACKUP_DIR"

if ls "$BACKUP_DIR"/*.tar.xz >/dev/null 2>&1; then
echo "ТЕСТ 2 ПРОЙДЕН: .tar.xz создан"
else
echo "ТЕСТ 2 ПРОВАЛЕН"
fi

echo "ТЕСТ 3: порог не превышен"
clean_env
create_file "small.log" 50 1
"$SCRIPT" "$TEST_DIR" 70 "$BACKUP_DIR"

if ls "$BACKUP_DIR"/*.tar.gz >/dev/null 2>&1; then
echo "ТЕСТ 3 ПРОВАЛЕН"
else
echo "ТЕСТ 3 ПРОЙДЕН"
fi

echo "ТЕСТ 4: пустая папка"
clean_env
"$SCRIPT" "$TEST_DIR" 70 "$BACKUP_DIR"

if [ $? -eq 0 ]; then
echo "ТЕСТ 4 ПРОЙДЕН"
else
echo "ТЕСТ 4 ПРОВАЛЕН"
fi

sudo umount "$TEST_DIR"
echo "все тесты завершены"
