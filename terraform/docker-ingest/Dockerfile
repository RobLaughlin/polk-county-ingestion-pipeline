FROM python:3.12.13-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:0.11.30 /uv /uvx /usr/local/bin/

# Keep the container environment outside the host-mounted application directory.
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Terraform mounts the source. Run the application on demand with docker exec.
CMD ["sleep", "infinity"]
