FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt ./
RUN python -m pip install --upgrade pip && pip install --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime
WORKDIR /app
RUN groupadd -r app && useradd -r -g app app
COPY --from=builder /install /usr/local
COPY app.py ./
RUN chown -R app:app /app
USER app
EXPOSE 5000
CMD ["python", "app.py"]