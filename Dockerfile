FROM debian:latest

RUN apt-get update && apt-get install -y \
    libdbi-perl \
    libdbd-mysql-perl \
    libjson-xs-perl \
    libfile-touch-perl \
    libmojolicious-perl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app

COPY . .

EXPOSE 8000

CMD [ "./bin/server.pl", "daemon", "--listen", "http://*:8000" ]