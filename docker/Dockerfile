FROM python:3.11-slim

WORKDIR /task_manager

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN pip install --upgrade pip

COPY ../../requirements.txt .
RUN pip install -r requirements.txt

COPY . .