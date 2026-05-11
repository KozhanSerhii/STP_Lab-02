#!/bin/bash

if [ "$1" = "1" ]; then
    docker rm -f static-site 2>/dev/null || true
    docker build -t static-site ./1-container
    docker run -d --name static-site -p 9000:9000 static-site
    docker ps
fi

if [ "$1" = "2" ]; then
    docker rm -f my-nginx 2>/dev/null || true
    docker run -d --name my-nginx -p 8080:80 \
    -v "$(pwd)/1-container:/usr/share/nginx/html:ro" \
    nginx
    docker ps
fi

if [ "$1" = "3" ]; then
    docker rm -f my-nginx 2>/dev/null || true
    docker run -d --name my-nginx -p 8080:80 \
    -v "$(pwd)/1-container:/usr/share/nginx/html:ro" \
    -v "$(pwd)/5-reverse-proxy/reverse_proxy.conf:/etc/nginx/conf.d/default.conf:ro" \
    nginx
    docker ps
fi

if [ "$1" = "4" ]; then
    cd 7-complete

    if [ ! -d "frontend" ]; then
        git clone https://gitlab.com/sealy/simple-todo-app frontend
    fi

    cd frontend
    git checkout backend-connection-vite
    npm install
    npm run build
    cd ..

    if [ ! -d "backend" ]; then
        git clone https://gitlab.com/sealy/simple-todo-backend backend
    fi

    cat > backend/Dockerfile <<'EOF'
FROM python:3.10-slim-buster

WORKDIR /app

RUN pip install --no-cache-dir poetry

COPY pyproject.toml poetry.lock* /app/

RUN poetry config virtualenvs.create false \
    && poetry install --no-root --no-interaction --no-ansi

COPY . /app

EXPOSE 5000

CMD ["poetry", "run", "python", "app.py"]
EOF

    cat > nginx.conf <<'EOF'
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
EOF

    cat > docker-compose.yml <<'EOF'
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
EOF

    docker compose up --build
fi

if [ "$1" = "5" ]; then
    docker rm -f static-site my-nginx compose-nginx frontend backend 2>/dev/null || true

    if [ -d "7-complete" ]; then
        cd 7-complete
        docker compose down --remove-orphans 2>/dev/null || true
        cd ..
    fi

    docker rmi static-site todo-backend 2>/dev/null || true
    docker ps
    docker images
fi
