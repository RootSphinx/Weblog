#!/usr/bin/env bash
NAME="djangoblog"
DJANGODIR=/code/djangoblog
USER=root
GROUP=root
NUM_WORKERS=1
DJANGO_WSGI_MODULE=djangoblog.wsgi

echo "Starting $NAME as `whoami`"

# 如果有挂载的源代码，拷贝进来使修改立即生效
if [ -d /host-source/djangoblog ]; then
  echo "Copying source code from /host-source..."
  # 保存前端构建产物（Docker build阶段生成，宿主可能没有）
  cp -r $DJANGODIR/blog/static/blog/dist /tmp/frontend-dist/ 2>/dev/null || true
  # 拷贝新代码
  cp -a /host-source/. $DJANGODIR/
  # 恢复前端构建产物
  cp -r /tmp/frontend-dist/. $DJANGODIR/blog/static/blog/dist/ 2>/dev/null || true
  echo "Source code synced."
fi

echo "Waiting for MySQL database to be ready..."
# 不断重试连接，直到成功为止才继续往下执行 manage.py
while ! python -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect(('db', 3306))" 2>/dev/null; do
    sleep 2
done
echo "MySQL is ready!"

cd $DJANGODIR

export PYTHONPATH=$DJANGODIR:$PYTHONPATH

python manage.py makemigrations && \
  python manage.py migrate && \
  python manage.py collectstatic --noinput  && \
  echo "Verifying Vite build artifacts..." && \
  ls -la blog/static/blog/dist/css/ && \
  ls -la blog/static/blog/dist/js/ && \
  echo "Vite manifest content:" && \
  cat blog/static/blog/dist/.vite/manifest.json && \
  echo "Copying .vite directory to collectedstatic..." && \
  mkdir -p collectedstatic/blog/dist/.vite && \
  cp -r blog/static/blog/dist/.vite/* collectedstatic/blog/dist/.vite/ && \
  python manage.py compress --force && \
  python manage.py build_index && \
  python manage.py compilemessages  || exit 1

exec gunicorn ${DJANGO_WSGI_MODULE}:application \
--name $NAME \
--workers $NUM_WORKERS \
--user=$USER --group=$GROUP \
--bind 0.0.0.0:8000 \
--log-level=debug \
--log-file=- \
--worker-class gevent \
--threads 4
