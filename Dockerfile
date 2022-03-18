FROM ubuntu:latest

WORKDIR /opt/SMART

COPY . .

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/London

RUN apt-get update && apt-get autoremove -y && apt install -y make gcc libdancer-perl libdancer-plugin-dbic-perl libdancer-plugin-database-perl libdancer-plugin-database-core-perl libdbd-sqlite2-perl libdbd-sqlite3-perl && cpan JSON && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/db && cp ./bin/smart.db /var/db

EXPOSE 3000

CMD ["perl", "./bin/app.pl"]
