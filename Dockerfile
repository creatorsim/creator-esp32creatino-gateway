# stolen from: https://github.com/timvancann/timnology-youtube/tree/main/videos/scalable-python-api

# --- Stage 1: Base image (IDF) ---
FROM espressif/idf:v5.3.2 AS base

# Python optimizations
ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1

WORKDIR /app


# --- Stage 2: Builder ---
FROM base AS builder

# cache dependencies w/ uv

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/
COPY esp32c3/pyproject.toml esp32c3/uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev



# --- Stage 3: Production ---
FROM base AS prod

# copy application
WORKDIR /app
COPY esp32c3 .

# get cached dependencies
COPY --from=builder /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/"

# expose ports (metadata)
EXPOSE 8080
EXPOSE 5000

# run
# just using python3 _should_ work, it's in the path, but idk why not
CMD ["/app/.venv/bin/python3", "gateway.py"]
