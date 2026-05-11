# Ми використовуємо інший базовий образ порівняно з початковим.
# У праймері ww використовується полегшена версія Linux під назвою Alpine Linux.
# У цьому контейнері ми будемо використовувати базовий контейнер python, що означає, що 
# python вже встановлено у контейнері. 

FROM python:3.10-slim-buster

WORKDIR /app

COPY . .

RUN chmod +x start.sh

EXPOSE 9000

CMD ["bash", "start.sh"]
