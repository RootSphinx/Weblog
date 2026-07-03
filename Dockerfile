# Stage 1: Build frontend assets
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# Copy frontend package files
COPY frontend/package*.json ./frontend/

# 使用 npmmirror 镜像源安装前端依赖
RUN cd frontend && \
    npm config set registry https://registry.npmmirror.com && \
    npm ci

# Copy frontend source files
COPY frontend/ ./frontend/
COPY templates/ ./templates/

# Build frontend assets
RUN cd frontend && npm run build


# Stage 2: Build final image
FROM python:3.11-slim

# 修改 Debian apt 源为清华大学镜像源，加快系统库安装速度
# 注意：Debian 12 (bookworm) 使用 debian.sources 格式
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    # 【修复关键点】必须加上 build-essential 和 pkg-config 才能成功编译 mysqlclient
    apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        default-libmysqlclient-dev \
        gettext && \
    rm -rf /var/lib/apt/lists/*

# 配置 pip 使用清华源
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

ENV PYTHONUNBUFFERED=1
WORKDIR /code/djangoblog/

# Copy and install Python dependencies
COPY requirements.txt requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn[gevent] && \
    pip cache purge

# Copy application code
COPY . .

# Remove old build artifacts
RUN rm -rf /code/djangoblog/blog/static/blog/dist

# Copy built frontend assets from frontend-builder stage
COPY --from=frontend-builder /app/blog/static/blog/dist /code/djangoblog/blog/static/blog/dist

# Set execute permission for entrypoint
RUN chmod +x /code/djangoblog/deploy/entrypoint.sh

ENTRYPOINT ["/code/djangoblog/deploy/entrypoint.sh"]
