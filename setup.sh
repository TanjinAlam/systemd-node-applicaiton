#!/bin/bash
exec > >(tee /var/log/setup.log) 2>&1
echo "Starting system setup..."

# Update system and install dependencies
apt-get update
apt-get upgrade -y
apt-get install -y curl git netcat-openbsd mysql-client

# Set up environment directory
export NVM_DIR="/usr/local/nvm"

# Install NVM if not already installed
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
fi

# Load NVM and install Node.js v18.16.1
export NVM_DIR="/usr/local/nvm"
source "$NVM_DIR/nvm.sh"
nvm install 18.16.1
nvm alias default 18.16.1
nvm use 18.16.1

# Verify Node.js version
NODE_PATH=$(nvm which 18.16.1)
echo "Node.js installed at: $NODE_PATH"
ln -sf "$NODE_PATH" /usr/local/bin/node

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
ExecStart=/usr/local/nvm/versions/node/v18.16.1/bin/node /temp/scripts/server.js
Environment="NVM_DIR=/usr/local/nvm"
Environment="PATH=/usr/local/nvm/versions/node/v18.16.1/bin:/usr/bin:/bin"
WorkingDirectory=/temp/scripts
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/node-app.log
StandardError=append:/var/log/node-app.log

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and enable Node.js service
systemctl daemon-reload
systemctl enable node-app
echo "Node.js service has been set up successfully."

echo "Setup complete! 🎉"
