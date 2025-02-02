FROM python:3.11-slim

WORKDIR /task_manager

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN pip install --upgrade pip

RUN echo "Current working directory: $(pwd)" && ls -alh

COPY ../../requirements.txt .
RUN pip install -r requirements.txt

COPY . .