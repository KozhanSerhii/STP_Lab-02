# Лабораторна робота №2

## Тема

**Контейнеризація застосунків за допомогою Docker**

## Мета роботи

Отримати практичні навички роботи з Docker, навчитися створювати Docker-образи та запускати контейнери, налаштовувати мережеву взаємодію між ними, використовувати Docker Compose для запуску багатоконтейнерних застосунків, а також розгорнути застосунок, що складається з frontend- і backend-частин, у контейнеризованому середовищі.

## Використані технології

- Docker
- Docker Compose
- Dockerfile
- Nginx
- Python HTTP Server
- Flask
- Vue / Vite
- Node.js та npm
- Git
- Vagrant
- VirtualBox
- Ubuntu

## Структура проєкту

```text
DOCKER/
├── 0-primer/
│   ├── Dockerfile
│   ├── analysis.txt
│   └── script.sh
├── 1-container/
│   ├── Dockerfile
│   ├── index.html
│   ├── style.css
│   ├── start.sh
│   └── container.log
├── 5-reverse-proxy/
│   └── reverse_proxy.conf
├── 6-compose/
│   └── docker-compose.yml
├── 7-complete/
│   ├── frontend/
│   ├── backend/
│   ├── nginx.conf
│   └── docker-compose.yml
├── todo-UA.sh
└── README.md
```

## Підготовка середовища

Лабораторна робота виконувалася у віртуальному середовищі Ubuntu, яке було розгорнуто за допомогою **Vagrant** та **VirtualBox**.

Запуск віртуальної машини:

```bash
vagrant up
```

Підключення до віртуальної машини:

```bash
vagrant ssh
```

Перехід до каталогу лабораторної роботи:

```bash
cd /vagrant/DOCKER
```

Перевірка роботи Docker:

```bash
docker run hello-world
```

Якщо Docker налаштовано правильно, буде виведено повідомлення:

```text
Hello from Docker!
```

## Завдання 0. Базова робота з Dockerfile

У папці `0-primer` розміщено перший приклад Dockerfile. Він створює простий образ на основі Alpine Linux.

```bash
cd 0-primer
docker build -t devops-primer .
docker images
docker run devops-primer
./script.sh
```

Команда `docker build -t devops-primer .` створює образ з назвою `devops-primer`. Символ `.` означає, що Dockerfile знаходиться у поточному каталозі.

Після зміни Dockerfile потрібно повторно зібрати образ:

```bash
docker build -t devops-primer .
docker run devops-primer
```

Цей етап демонструє різницю між середовищем контейнера та хост-системою.

## Завдання 1. Створення контейнера зі статичним сайтом

У папці `1-container` знаходиться простий статичний сайт.

```bash
cd ../1-container
./start.sh
```

Сайт доступний у браузері за адресою:

```text
http://127.0.0.1:9000
```

Dockerfile для контейнеризації сайту:

```dockerfile
FROM python:3.10-slim-buster

WORKDIR /app

COPY . .

RUN chmod +x start.sh

EXPOSE 9000

CMD ["bash", "start.sh"]
```

Збірка образу:

```bash
docker build -t static-site .
```

Запуск контейнера:

```bash
docker run --name static-site -p 9000:9000 static-site
```

Запуск контейнера у фоновому режимі:

```bash
docker run -d --name static-site -p 9000:9000 static-site
```

## Завдання 2. Автоматизація запуску контейнера

Для автоматизації використовується скрипт `todo-UA.sh`.

```bash
./todo-UA.sh 1
```

Скрипт виконує такі дії:

1. Видаляє старий контейнер `static-site`, якщо він існує.
2. Збирає Docker-образ `static-site`.
3. Запускає контейнер у фоновому режимі.
4. Виводить список запущених контейнерів.

Перевірка контейнерів:

```bash
docker ps
```

## Завдання 3. Діагностика контейнера

Підключення до контейнера:

```bash
docker exec -it static-site bash
```

Пошук файлу журналу:

```bash
find / -name log.txt 2>/dev/null
```

Перегляд журналу:

```bash
cat /app/log.txt
```

Вихід з контейнера:

```bash
exit
```

Копіювання журналу на хост:

```bash
docker cp static-site:/app/log.txt ./1-container/container.log
```

Перевірка скопійованого файлу:

```bash
cat ./1-container/container.log
```

## Завдання 4. Запуск готового образу Nginx

Запуск стандартного контейнера Nginx:

```bash
docker run --name my-nginx -p 8080:80 nginx
```

Сторінка доступна за адресою:

```text
http://127.0.0.1:8080
```

Запуск Nginx зі статичним сайтом через volume mapping:

```bash
docker run -d --name my-nginx -p 8080:80 \
-v /vagrant/DOCKER/1-container:/usr/share/nginx/html:ro \
nginx
```

Якщо у середовищі Vagrant сторінка відображається некоректно, у конфігурації Nginx потрібно вимкнути `sendfile`:

```nginx
sendfile off;
```

## Завдання 5. Reverse Proxy

Файл конфігурації:

```text
5-reverse-proxy/reverse_proxy.conf
```

Приклад конфігурації reverse proxy:

```nginx
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    sendfile off;

    location / {
        try_files $uri $uri/ =404;
    }

    location /joke {
        proxy_pass https://official-joke-api.appspot.com/random_joke;
        proxy_ssl_server_name on;
        proxy_set_header Host official-joke-api.appspot.com;
    }
}
```

Запуск Nginx з reverse proxy:

```bash
docker run -d --name my-nginx -p 8080:80 \
-v /vagrant/DOCKER/1-container:/usr/share/nginx/html:ro \
-v /vagrant/DOCKER/5-reverse-proxy/reverse_proxy.conf:/etc/nginx/conf.d/default.conf:ro \
nginx
```

Перевірка сайту:

```text
http://127.0.0.1:8080
```

Перевірка proxy-запиту:

```text
http://127.0.0.1:8080/joke
```

## Завдання 6. Docker Compose

У папці `6-compose` створюється файл `docker-compose.yml`.

```yaml
services:
  nginx:
    image: nginx
    container_name: compose-nginx
    ports:
      - "8080:80"
    volumes:
      - ../1-container:/usr/share/nginx/html:ro
```

Запуск:

```bash
cd 6-compose
docker compose up
```

Зупинка:

```bash
docker compose down
```

## Завдання 7. Frontend та Backend застосунок

У цьому завданні запускається застосунок, який складається з двох частин:

- `frontend` — клієнтська частина;
- `backend` — серверна частина.

Перехід до папки:

```bash
cd ../7-complete
```

Клонування і збірка frontend:

```bash
git clone https://gitlab.com/sealy/simple-todo-app frontend
cd frontend
git checkout backend-connection-vite
npm install
node node_modules/vite/bin/vite.js build
cd ..
```

Після збірки створюється папка `frontend/dist`.

Клонування backend:

```bash
git clone https://gitlab.com/sealy/simple-todo-backend backend
```

Dockerfile для backend:

```dockerfile
FROM python:3.10-slim-buster

WORKDIR /app

RUN pip install --no-cache-dir poetry

COPY . /app

RUN poetry config virtualenvs.create false \
    && poetry lock \
    && poetry install --no-root --no-interaction --no-ansi

EXPOSE 5000

CMD ["poetry", "run", "python", "app.py"]
```

Конфігурація Nginx для frontend і proxy-запитів до backend:

```nginx
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    sendfile off;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /todos {
        proxy_pass http://backend:5000/todos;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Файл `docker-compose.yml`:

```yaml
services:
  backend:
    image: todo-backend
    build:
      context: ./backend
    container_name: backend
    expose:
      - "5000"

  frontend:
    image: nginx
    container_name: frontend
    depends_on:
      - backend
    ports:
      - "8080:80"
    volumes:
      - ./frontend/dist:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

Запуск застосунку:

```bash
docker compose up --build
```

Перевірка frontend:

```text
http://127.0.0.1:8080
```

Перевірка backend API:

```text
http://127.0.0.1:8080/todos
```

## Завдання 8. Очищення контейнерів та образів

Зупинка Docker Compose:

```bash
docker compose down --remove-orphans
```

Видалення контейнерів:

```bash
docker rm -f static-site my-nginx compose-nginx frontend backend 2>/dev/null || true
```

Видалення створених образів:

```bash
docker rmi static-site todo-backend 2>/dev/null || true
```

Перевірка контейнерів:

```bash
docker ps
```

Перевірка образів:

```bash
docker images
```

## Основні команди

| Команда | Призначення |
|---|---|
| `docker build -t name .` | Збірка Docker-образу |
| `docker run image` | Запуск контейнера з образу |
| `docker run -d` | Запуск контейнера у фоновому режимі |
| `docker ps` | Перегляд запущених контейнерів |
| `docker images` | Перегляд локальних образів |
| `docker exec -it container bash` | Підключення до контейнера |
| `docker cp` | Копіювання файлів між контейнером і хостом |
| `docker rm -f container` | Видалення контейнера |
| `docker rmi image` | Видалення образу |
| `docker compose up --build` | Збірка та запуск сервісів Docker Compose |
| `docker compose down` | Зупинка сервісів Docker Compose |

## Висновок

У ході лабораторної роботи було отримано практичні навички роботи з Docker та контейнеризацією застосунків. Було створено власні Docker-образи, запущено контейнери, налаштовано проброс портів, volume mapping, reverse proxy за допомогою Nginx та Docker Compose для запуску декількох сервісів.

Також було реалізовано розгортання застосунку, що складається з frontend- та backend-частин. Frontend було зібрано за допомогою Vite, backend запущено в окремому контейнері, а взаємодію між ними налаштовано через Nginx reverse proxy.

Отримані навички можуть бути використані для розгортання вебзастосунків, створення ізольованого середовища розробки та автоматизації запуску багатокомпонентних проєктів.
