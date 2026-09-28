FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN python -m pip install --no-cache-dir --require-hashes --only-binary :all: -r requirements.txt

COPY app ./app
COPY contracts ./contracts

RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 10000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-10000}"]
