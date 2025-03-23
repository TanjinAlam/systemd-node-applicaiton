# #!/bin/bash
# exec > >(tee /var/log/setup.log) 2>&1
# echo "Starting system setup..."

# # Update system and install dependencies
# apt-get update
# apt-get upgrade -y
# apt-get install -y curl git netcat-openbsd mysql-client


# # Install NVM
# echo "Installing NVM..."
# curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash

# # Load NVM for current session
# # export NVM_DIR="$HOME/.nvm"
# # source "$NVM_DIR/nvm.sh"

# echo 'export NVM_DIR="/home/ubuntu/.nvm"' >> /home/ubuntu/.bashrc
# echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> /home/ubuntu/.bashrc
# # Dot source the files to ensure that variables are available within the current shell
# . /home/ubuntu/.nvm/nvm.sh
# . /home/ubuntu/.profile
# . /home/ubuntu/.bashrc

# # Install Node.js (specific version)
# echo "Installing Node.js v18.16.1..."
# # Install NVM, NPM, Node.JS & Grunt
# nvm alias default 18.16.1
# nvm install 18.16.1
# nvm use 18.16.1

# # Create MySQL check script
# mkdir -p /usr/local/bin
# cat > /usr/local/bin/check-mysql.sh << 'EOL'
# #!/bin/bash
# DB_HOST="$DB_PRIVATE_IP"
# DB_PORT=3306
# MAX_RETRIES=30
# RETRY_INTERVAL=10

# check_mysql() {
#   nc -z "$DB_HOST" "$DB_PORT"
#   return $?
# }

# retry_count=0
# while [ $retry_count -lt $MAX_RETRIES ]; do
#   if check_mysql; then
#     echo "Successfully connected to MySQL at $DB_HOST:$DB_PORT"
#     exit 0
#   fi
#   echo "Attempt $((retry_count + 1))/$MAX_RETRIES: Cannot connect to MySQL at $DB_HOST:$DB_PORT. Retrying in $RETRY_INTERVAL seconds..."
#   sleep $RETRY_INTERVAL
#   retry_count=$((retry_count + 1))
# done

# echo "Failed to connect to MySQL after $MAX_RETRIES attempts"
# exit 1
# EOL

# chmod +x /usr/local/bin/check-mysql.sh

# # Wait for DB_PRIVATE_IP to be available
# max_attempts=30
# attempt=0
# while [ -z "$DB_PRIVATE_IP" ]; do
#     if [ $attempt -ge $max_attempts ]; then
#         echo "Timeout waiting for DB_PRIVATE_IP to be set"
#         exit 1
#     fi
#     echo "Waiting for DB_PRIVATE_IP environment variable..."
#     attempt=$((attempt + 1))
#     sleep 10
#     source /etc/environment
# done
# echo "DB_PRIVATE_IP is set to: $DB_PRIVATE_IP"

# # Create MySQL check systemd service
# cat > /etc/systemd/system/mysql-check.service << 'EOL'
# [Unit]
# Description=MySQL Connectivity Check Service
# After=network.target
# Wants=network.target

# [Service]
# Type=simple
# EnvironmentFile=/etc/environment
# ExecStart=/usr/local/bin/check-mysql.sh
# Restart=on-failure
# RestartSec=30
# User=ubuntu
# StandardOutput=append:/var/log/mysql-check.log
# StandardError=append:/var/log/mysql-check.log

# [Install]
# WantedBy=multi-user.target
# EOL

# # Reload systemd and start MySQL check service
# systemctl daemon-reload
# systemctl enable mysql-check
# systemctl start mysql-check
# echo "MySQL check service has been started."

# # Create Node.js systemd service that depends on MySQL check service
# bash -c 'cat > /etc/systemd/system/node-app.service << EOL
# [Unit]
# Description=Start Node.js App
# After=mysql-check.service
# Requires=mysql-check.service

# [Service]
# ExecStart=/home/ubuntu/.nvm/versions/node/v18.16.1/bin/node /tmp/scripts/server.js
# Environment="NVM_DIR=/home/ubuntu/.nvm"
# Environment="PATH=/home/ubuntu/.nvm/versions/node/v18.16.1/bin:/usr/bin:/bin"
# WorkingDirectory=/tmp/scripts
# Restart=on-failure
# RestartSec=10
# User=ubuntu
# StandardOutput=append:/var/log/node-app.log
# StandardError=append:/var/log/node-app.log

# [Install]
# WantedBy=multi-user.target
# EOL'

# # Reload systemd and enable Node.js service
# systemctl daemon-reload
# systemctl enable node-app
# echo "Node.js service has been set up successfully."


# # Download health check script from GitHub Gist
# mkdir -p /usr/local/bin
# wget -O /usr/local/bin/node_health_check.sh https://gist.githubusercontent.com/TanjinAlam/decb3a089e5581323b50a35abbf5ceb0/raw/2dac8096de5c8f0ef2a0464129461fc5cb7e82f9/server_health_check
# chmod +x /usr/local/bin/node_health_check.sh

# # Create log files and set permissions
# touch /var/log/nodejs-health.log /var/log/nodejs-warnings.log
# chmod 644 /var/log/nodejs-health.log /var/log/nodejs-warnings.log

# # Create a wrapper script that runs the health check every 10 seconds
# cat > /usr/local/bin/health_check_loop.sh << 'EOL'
# #!/bin/bash
# while true; do
#   /usr/local/bin/node_health_check.sh
#   sleep 10
# done
# EOL
# chmod +x /usr/local/bin/health_check_loop.sh

# # Add cron job to run at system startup
# (crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/health_check_loop.sh > /dev/null 2>&1 &") | crontab -

# # Start the health check loop immediately
# nohup /usr/local/bin/health_check_loop.sh > /dev/null 2>&1 &

# # Start and enable cron service
# systemctl start cron
# systemctl enable cron

# echo "Health check setup with crontab completed successfully"

# echo "Setup complete! 🎉"




#!/bin/bash
exec > >(tee /var/log/setup.log) 2>&1
echo "Starting system setup..."

# Update system and install dependencies
apt-get update
apt-get upgrade -y
apt-get install -y curl git netcat-openbsd mysql-client

# Create MySQL check script
mkdir -p /usr/local/bin
cat > /usr/local/bin/check-mysql.sh << 'EOL'
#!/bin/bash
DB_HOST="$DB_PRIVATE_IP"
DB_PORT=3306
MAX_RETRIES=30
RETRY_INTERVAL=10

check_mysql() {
  nc -z "$DB_HOST" "$DB_PORT"
  return $?
}

retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
  if check_mysql; then
    echo "Successfully connected to MySQL at $DB_HOST:$DB_PORT"
    exit 0
  fi
  echo "Attempt $((retry_count + 1))/$MAX_RETRIES: Cannot connect to MySQL at $DB_HOST:$DB_PORT. Retrying in $RETRY_INTERVAL seconds..."
  sleep $RETRY_INTERVAL
  retry_count=$((retry_count + 1))
done

echo "Failed to connect to MySQL after $MAX_RETRIES attempts"
exit 1
EOL

chmod +x /usr/local/bin/check-mysql.sh

# Wait for DB_PRIVATE_IP to be available
max_attempts=30
attempt=0
while [ -z "$DB_PRIVATE_IP" ]; do
    if [ $attempt -ge $max_attempts ]; then
        echo "Timeout waiting for DB_PRIVATE_IP to be set"
        exit 1
    fi
    echo "Waiting for DB_PRIVATE_IP environment variable..."
    attempt=$((attempt + 1))
    sleep 10
    source /etc/environment
done
echo "DB_PRIVATE_IP is set to: $DB_PRIVATE_IP"

# Create MySQL check systemd service
cat > /etc/systemd/system/mysql-check.service << 'EOL'
[Unit]
Description=MySQL Connectivity Check Service
After=network.target
Wants=network.target

[Service]
Type=simple
EnvironmentFile=/etc/environment
ExecStart=/usr/local/bin/check-mysql.sh
Restart=on-failure
RestartSec=30
User=ubuntu
StandardOutput=append:/var/log/mysql-check.log
StandardError=append:/var/log/mysql-check.log

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and start MySQL check service
systemctl daemon-reload
systemctl enable mysql-check
systemctl start mysql-check
echo "MySQL check service has been started."

# Create Node.js systemd service that depends on MySQL check service
cat > /etc/systemd/system/node-app.service << 'EOL'
[Unit]
Description=Start Node.js App
After=mysql-check.service
Requires=mysql-check.service

[Service]
ExecStart=/home/ubuntu/.nvm/versions/node/v18.16.1/bin/node /tmp/scripts/server.js
Environment="NVM_DIR=/home/ubuntu/.nvm"
Environment="PATH=/home/ubuntu/.nvm/versions/node/v18.16.1/bin:/usr/bin:/bin"
WorkingDirectory=/tmp/scripts
Restart=on-failure
RestartSec=10
User=ubuntu
StandardOutput=append:/var/log/node-app.log
StandardError=append:/var/log/node-app.log

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and enable Node.js service
systemctl daemon-reload
systemctl enable node-app
echo "Node.js service has been set up successfully."

# Download health check script from GitHub Gist
mkdir -p /usr/local/bin
wget -O /usr/local/bin/node_health_check.sh https://gist.githubusercontent.com/TanjinAlam/decb3a089e5581323b50a35abbf5ceb0/raw/2dac8096de5c8f0ef2a0464129461fc5cb7e82f9/server_health_check
chmod +x /usr/local/bin/node_health_check.sh

# Create log files and set permissions
touch /var/log/nodejs-health.log /var/log/nodejs-warnings.log
chmod 644 /var/log/nodejs-health.log /var/log/nodejs-warnings.log
chown ubuntu:ubuntu /var/log/nodejs-health.log /var/log/nodejs-warnings.log

# Create a wrapper script that runs the health check every 10 seconds
cat > /usr/local/bin/health_check_loop.sh << 'EOL'
#!/bin/bash
while true; do
  /usr/local/bin/node_health_check.sh
  sleep 10
done
EOL
chmod +x /usr/local/bin/health_check_loop.sh

# Add cron job to run at system startup
(crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/health_check_loop.sh > /dev/null 2>&1 &") | crontab -

# Start the health check loop immediately
nohup /usr/local/bin/health_check_loop.sh > /dev/null 2>&1 &

# Start and enable cron service
systemctl start cron
systemctl enable cron

echo "Health check setup with crontab completed successfully"
echo "Setup complete! 🎉"
