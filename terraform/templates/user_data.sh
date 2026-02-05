#!/bin/bash
set -e

# Log everything to a file for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Starting user data script ==="

# Update system
dnf update -y

# Install Node.js 20
dnf install -y nodejs20 npm git

# Create node symlinks
alternatives --install /usr/bin/node node /usr/bin/node-20 100
alternatives --install /usr/bin/npm npm /usr/bin/npm-20 100

# Install PM2 globally
npm install -g pm2

# Create app directory
mkdir -p /opt/the-dailies
chown ec2-user:ec2-user /opt/the-dailies

# Create environment file
cat > /opt/the-dailies/.env << 'ENVEOF'
NODE_ENV=production
PORT=3000
MONGODB_URI=${mongodb_uri}
JWT_SECRET=${jwt_secret}
CORS_ORIGINS=${cors_origins}
ANTHROPIC_API_KEY=${anthropic_api_key}
SMTP_HOST=smtp.gmail.com
SMTP_PORT=465
SMTP_USER=${smtp_user}
SMTP_PASS=${smtp_pass}
FEEDBACK_EMAIL=${feedback_email}
GITHUB_TOKEN=${github_token}
GITHUB_REPOSITORY=${github_repository}
ENVEOF

chown ec2-user:ec2-user /opt/the-dailies/.env
chmod 600 /opt/the-dailies/.env

# Create deployment script
cat > /opt/the-dailies/deploy.sh << 'DEPLOYEOF'
#!/bin/bash
set -e

cd /opt/the-dailies

# Load environment
source .env

# Install dependencies and build
cd backend
npm ci --production=false
npm run build

# Start/restart with PM2
pm2 delete the-dailies-api 2>/dev/null || true
pm2 start dist/main.js --name the-dailies-api --env production
pm2 save

echo "Deployment complete!"
DEPLOYEOF

chmod +x /opt/the-dailies/deploy.sh
chown ec2-user:ec2-user /opt/the-dailies/deploy.sh

# Setup PM2 to start on boot
env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user

# Install nginx for reverse proxy
dnf install -y nginx

# Configure nginx
cat > /etc/nginx/conf.d/the-dailies.conf << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:3000/api/puzzles/today;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
NGINXEOF

# Remove default nginx config
rm -f /etc/nginx/conf.d/default.conf

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

echo "=== User data script complete ==="
