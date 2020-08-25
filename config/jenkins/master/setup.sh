#!/usr/bin/env bash
set -eox pipefail

if [[ -z $JENKINS_PUBLIC_DNS_ADDRESS ]]; then echo "The env variable JENKINS_PUBLIC_DNS_ADDRESS is not set"; exit 1; fi

#
# Update repos packages
#
apt-get update

#
# Install Docker
#
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

#
# Install NGinx
#
apt-get install -y nginx

#
# Setup SSL certificates via certbot
#
add-apt-repository -y ppa:certbot/certbot
apt-get update
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d $JENKINS_PUBLIC_DNS_ADDRESS --non-interactive --agree-tos -m oesdk-ci@microsoft.com

#
# Pull Jenkins master LTS Docker images
#
docker pull jenkins/jenkins:lts

#
# Create CasC directory
#
mkdir -p /var/jenkins_home/casc

#
# Start Jenkins master via systemd service and enable it on boot
#
cat << EOF > /etc/systemd/system/jenkins.service
[Unit]
Description=OpenEnclave Jenkins master
Requires=docker.service
After=docker.service

[Service]
Type=simple
Restart=always
TimeoutStartSec=60
ExecStartPre=/usr/bin/docker pull jenkins/jenkins:lts
ExecStartPre=-/usr/bin/docker rm -f %p
ExecStart=/usr/bin/docker run \\
    --name %p \\
    -v /var/run/docker.sock:/var/run/docker.sock \\
    -v /var/jenkins_home:/var/jenkins_home \\
    -e JAVA_OPTS="-Djava.awt.headless=true -Dmail.smtp.starttls.enable=true" \\
    -e CASC_JENKINS_CONFIG="/var/jenkins_home/casc" \\
    --user root -p 8080:8080 -p 50000:50000 \\
    jenkins/jenkins:lts
ExecStop=/usr/bin/docker stop %p

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins


#
# Setup Jenkins master HTTPS proxy with NGinx
#
cat << EOF > /etc/nginx/sites-available/jenkins
server {
    listen 80;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443;
    server_name ${JENKINS_PUBLIC_DNS_ADDRESS};
    ssl_certificate /etc/letsencrypt/live/${JENKINS_PUBLIC_DNS_ADDRESS}/fullchain.pem;   # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/${JENKINS_PUBLIC_DNS_ADDRESS}/privkey.pem; # managed by Certbot

    ssl on;
    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         "TLS13-AES-256-GCM-SHA384:TLS13-AES-128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384";
    ssl_prefer_server_ciphers on;

    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    access_log            /var/log/nginx/jenkins.access.log;

    location / {
      proxy_set_header        Host \$host;
      proxy_set_header        X-Real-IP \$remote_addr;
      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;
      # Fix the "It appears that your reverse proxy set up is broken" error.
      proxy_pass          http://localhost:8080;
      proxy_read_timeout  90;
      proxy_redirect      http://localhost:8080 https://${JENKINS_PUBLIC_DNS_ADDRESS};
    }
}
EOF
ln -sfn /etc/nginx/sites-available/jenkins /etc/nginx/sites-available/default
systemctl reload nginx
