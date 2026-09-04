#!/bin/bash
set -euo pipefail

rollback_api() {
  cp -a /var/lib/zomboclat/api_server.py.pre-security-20260904 /var/lib/zomboclat/api_server.py
  cp -a /var/lib/zomboclat/config_manager.py.pre-security-20260904 /var/lib/zomboclat/config_manager.py
  cp -a /etc/systemd/system/zomboclat-api.service.pre-security-20260904 /etc/systemd/system/zomboclat-api.service
  systemctl daemon-reload
  systemctl restart zomboclat-api.service
}

install -m 640 -o pzserver -g pzserver /tmp/api_server.py /var/lib/zomboclat/api_server.py
install -m 640 -o pzserver -g pzserver /tmp/config_manager.py /var/lib/zomboclat/config_manager.py
chown pzserver:pzserver /var/lib/zomboclat
find /var/lib/zomboclat -maxdepth 1 -type f \( -name '*.db' -o -name '*.json' \) -exec chown pzserver:pzserver {} +
chmod 640 /var/lib/zomboclat/zomboclat.db

install -m 644 /tmp/49-zomboclat.rules /etc/polkit-1/rules.d/49-zomboclat.rules
install -m 644 /tmp/zomboclat-api.service /etc/systemd/system/zomboclat-api.service
systemctl daemon-reload
systemctl try-restart polkit.service || true
if ! systemctl restart zomboclat-api.service; then
  rollback_api
  exit 1
fi

api_ready=false
for _ in $(seq 1 30); do
  if curl --fail --silent http://127.0.0.1:28080/health >/dev/null; then
    api_ready=true
    break
  fi
  sleep 0.25
done
if ! "$api_ready"; then
  rollback_api
  exit 1
fi

test "$(curl --silent --output /dev/null --write-out '%{http_code}' http://127.0.0.1:28080/api/users)" = 401
test "$(systemctl show zomboclat-api.service -p User --value)" = pzserver
runuser -u pzserver -- systemctl start pzserver.service

install -d -m 755 /var/www/certbot
install -m 644 /tmp/zomboclat-nginx.conf /etc/nginx/sites-available/zomboclat
ln -sfn /etc/nginx/sites-available/zomboclat /etc/nginx/sites-enabled/zomboclat
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx.service

install -m 755 /tmp/reload-nginx /etc/letsencrypt/renewal-hooks/deploy/reload-nginx
install -m 644 /tmp/fail2ban-sshd.local /etc/fail2ban/jail.d/sshd.local
systemctl enable --now fail2ban.service
fail2ban-client reload

install -m 644 /tmp/00-zomboclat-ssh-hardening.conf /etc/ssh/sshd_config.d/00-zomboclat-hardening.conf
rm -f /etc/ssh/sshd_config.d/99-zomboclat-hardening.conf
sshd -t
systemctl reload ssh.service

install -m 755 /tmp/pzserver-backup /usr/local/sbin/pzserver-backup
ufw --force delete allow 28080/tcp || true

curl --fail --silent https://45.142.115.19/health >/dev/null
test "$(curl --silent --output /dev/null --write-out '%{http_code}' https://45.142.115.19/api/users)" = 401
