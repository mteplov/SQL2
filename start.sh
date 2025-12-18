#!/bin/bash

echo "======================================================"
echo "   ЗАПУСК ПРОЕКТА ШАРДИРОВАНИЯ"
echo "======================================================"

PROJECT_DIR="sharding_project"
SQL_DIR="$PROJECT_DIR/sql"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

export PGPASSWORD="password"

# -------------------------------
# 1. Создание структуры проекта
# -------------------------------
echo "[STEP] Создаем структуру проекта..."
mkdir -p "$SQL_DIR"
echo "[OK] Папки созданы"

# -------------------------------
# 2. Создание docker-compose.yml (без version)
# -------------------------------
echo "[STEP] Создаем docker-compose.yml..."
cat > $COMPOSE_FILE <<EOF
services:
  users_shard1_master:
    image: postgres:16
    container_name: users_shard1_master
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: users_shard1
    ports:
      - "5433:5432"
    volumes:
      - ./sql/init_users_shard1.sql:/docker-entrypoint-initdb.d/init.sql

  users_shard1_slave:
    image: postgres:16
    container_name: users_shard1_slave
    environment:
      POSTGRES_PASSWORD: password
    depends_on:
      - users_shard1_master
    command:
      - "postgres"
      - "-c"
      - "hot_standby=on"
    ports:
      - "5434:5432"

  users_shard2_master:
    image: postgres:16
    container_name: users_shard2_master
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: users_shard2
    ports:
      - "5435:5432"
    volumes:
      - ./sql/init_users_shard2.sql:/docker-entrypoint-initdb.d/init.sql

  users_shard2_slave:
    image: postgres:16
    container_name: users_shard2_slave
    environment:
      POSTGRES_PASSWORD: password
    depends_on:
      - users_shard2_master
    command:
      - "postgres"
      - "-c"
      - "hot_standby=on"
    ports:
      - "5436:5432"

  books_master:
    image: postgres:16
    container_name: books_master
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: books
    ports:
      - "5437:5432"
    volumes:
      - ./sql/init_books.sql:/docker-entrypoint-initdb.d/init.sql

  stores_master:
    image: postgres:16
    container_name: stores_master
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: stores
    ports:
      - "5438:5432"
    volumes:
      - ./sql/init_stores.sql:/docker-entrypoint-initdb.d/init.sql
EOF
echo "[OK] docker-compose.yml создан"

# -------------------------------
# 3. Создание SQL-файлов
# -------------------------------
echo "[STEP] Создаем SQL-файлы..."
echo "CREATE TABLE users(id BIGINT PRIMARY KEY, name TEXT, email TEXT);" > "$SQL_DIR/init_users_shard1.sql"
echo "CREATE TABLE users(id BIGINT PRIMARY KEY, name TEXT, email TEXT);" > "$SQL_DIR/init_users_shard2.sql"
echo "CREATE TABLE books(id BIGSERIAL PRIMARY KEY, title TEXT, category TEXT);" > "$SQL_DIR/init_books.sql"
echo "CREATE TABLE stores(id BIGSERIAL PRIMARY KEY, name TEXT, city TEXT);" > "$SQL_DIR/init_stores.sql"
echo "[OK] SQL-файлы созданы"

# -------------------------------
# 4. Запуск контейнеров
# -------------------------------
echo "[STEP] Поднимаем Docker контейнеры..."
docker compose -f $COMPOSE_FILE up -d
sleep 10
echo "[OK] Контейнеры подняты"

# -------------------------------
# 5. Проверки доступности баз
# -------------------------------
check_db() {
    PORT=$1
    DB=$2
    echo "[CHECK] Проверка доступности БД $DB на порту $PORT..."
    psql -h localhost -p $PORT -U postgres -d $DB -c "SELECT 1;" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[ERROR] БД $DB недоступна!"
        exit 1
    else
        echo "[OK] БД $DB доступна"
    fi
}

check_db 5433 users_shard1
check_db 5435 users_shard2
check_db 5437 books
check_db 5438 stores

# -------------------------------
# 6. Проверка горизонтального шардирования
# -------------------------------
echo "[CHECK] Проверка горизонтального шардирования пользователей..."
psql -h localhost -p 5433 -U postgres -d users_shard1 -c "INSERT INTO users VALUES (1000,'Alice','alice@mail.com');" > /dev/null
psql -h localhost -p 5435 -U postgres -d users_shard2 -c "INSERT INTO users VALUES (15000000,'Bob','bob@mail.com');" > /dev/null

S1=$(psql -h localhost -p 5433 -U postgres -d users_shard1 -t -c "SELECT count(*) FROM users WHERE id=1000;")
S2=$(psql -h localhost -p 5435 -U postgres -d users_shard2 -t -c "SELECT count(*) FROM users WHERE id=15000000;")

if [[ "$S1" -eq 1 && "$S2" -eq 1 ]]; then
    echo "[OK] Горизонтальное шардирование пользователей работает"
else
    echo "[ERROR] Проблема с горизонтальным шардированием"
    exit 1
fi

# -------------------------------
# 7. Проверка вертикального шардирования
# -------------------------------
echo "[CHECK] Проверка вертикального шардирования (books/stores)..."
psql -h localhost -p 5437 -U postgres -d books -c "INSERT INTO books(title,category) VALUES ('SQL Bible','DB');" > /dev/null
psql -h localhost -p 5438 -U postgres -d stores -c "INSERT INTO stores(name,city) VALUES ('Main Store','NY');" > /dev/null

BOOKS_COUNT=$(psql -h localhost -p 5437 -U postgres -d books -t -c "SELECT count(*) FROM books;")
STORES_COUNT=$(psql -h localhost -p 5438 -U postgres -d stores -t -c "SELECT count(*) FROM stores;")

if [[ "$BOOKS_COUNT" -ge 1 && "$STORES_COUNT" -ge 1 ]]; then
    echo "[OK] Вертикальное шардирование работает"
else
    echo "[ERROR] Проблема с вертикальным шардированием"
    exit 1
fi

echo ""
echo "======================================================"
echo "     ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ — Система готова"
echo "======================================================"

