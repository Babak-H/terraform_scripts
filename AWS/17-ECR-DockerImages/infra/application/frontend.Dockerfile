FROM python:3.9.4-alpine AS base

WORKDIR /usr/src

RUN pip install --upgrade pip setuptools wheel
RUN touch /usr/src/front.sh

ENTRYPOINT [ "sh", "/usr/src/front.sh" ]