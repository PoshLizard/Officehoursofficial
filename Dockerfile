FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN mkdir -p /app/data && chmod 777 /app/data

ENV PORT=3000
EXPOSE 3000

# Shell form so $PORT (injected by most hosts) expands at runtime.
# Set SECRET_KEY in the hosting environment — do not bake a secret into the image.
CMD gunicorn --bind 0.0.0.0:${PORT:-3000} app:app
