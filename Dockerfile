FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN useradd --create-home --uid 10001 appuser \
    && mkdir -p /app /opt/venv \
    && chown -R appuser:appuser /app /opt/venv

COPY --chown=appuser:appuser requirements.txt .

USER appuser
RUN python -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --no-cache-dir --require-hashes --only-binary :all: -r requirements.txt
ENV PATH="/opt/venv/bin:$PATH"

COPY --chown=appuser:appuser app ./app
COPY --chown=appuser:appuser contracts ./contracts

EXPOSE 10000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-10000}"]
