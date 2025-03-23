#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print with color
print_status() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
fi

# Update system packages
print_status "Updating system packages..."
apt update && apt upgrade -y || print_error "Failed to update system packages"

# Install required packages
print_status "Installing required packages..."
apt install -y curl git build-essential || print_error "Failed to install required packages"

# Install Node.js 18.x
print_status "Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs || print_error "Failed to install Node.js"

# Install PM2 globally
print_status "Installing PM2..."
npm install -g pm2 || print_error "Failed to install PM2"

# Install PostgreSQL
print_status "Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib || print_error "Failed to install PostgreSQL"

# Configure PostgreSQL
print_status "Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE USER nextuser WITH PASSWORD 'nextpass123';" || print_warning "User might already exist"
sudo -u postgres psql -c "CREATE DATABASE nextdb OWNER nextuser;" || print_warning "Database might already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextdb TO nextuser;" || print_warning "Privileges might already be granted"

# Configure firewall
print_status "Configuring firewall..."
ufw allow 22/tcp # SSH
ufw allow 80/tcp # HTTP
ufw allow 443/tcp # HTTPS
ufw allow 3000/tcp # Next.js app
ufw --force enable

# Create project directory
print_status "Creating project directory..."
mkdir -p /var/www/next-app
cd /var/www/next-app || print_error "Failed to create project directory"

# Create package.json if it doesn't exist
print_status "Creating initial package.json..."
cat > package.json << EOL
{
  "name": "physics-practice",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:studio": "prisma studio",
    "db:seed": "ts-node prisma/seed.ts"
  },
  "dependencies": {
    "@auth/core": "^0.18.0",
    "@prisma/client": "^5.0.0",
    "@tabler/icons-react": "^2.40.0",
    "@tremor/react": "^3.11.1",
    "bcryptjs": "^2.4.3",
    "jose": "^5.2.0",
    "next": "14.0.4",
    "next-auth": "^4.24.5",
    "react": "^18",
    "react-dom": "^18",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "eslint": "^8",
    "eslint-config-next": "14.0.4",
    "postcss": "^8",
    "prisma": "^5.0.0",
    "tailwindcss": "^3.3.0",
    "ts-node": "^10.9.1",
    "typescript": "^5"
  }
}
EOL

# Clone the repository
print_status "Cloning the repository..."
git clone https://github.com/smartsina/Physics-Practice.git temp || print_error "Failed to clone repository"

# Copy files from temp directory
print_status "Copying project files..."
cp -r temp/* . || print_error "Failed to copy project files"
cp -r temp/.* . 2>/dev/null || print_warning "No hidden files to copy"
rm -rf temp

# Install project dependencies
print_status "Installing project dependencies..."
npm install || print_error "Failed to install project dependencies"

# Create .env file
print_status "Creating .env file..."
cat > .env << EOL
DATABASE_URL="postgresql://nextuser:nextpass123@localhost:5432/nextdb?schema=public"
NEXT_PUBLIC_API_URL="http://151.80.52.16:3000"
PORT=3000
JWT_SECRET="$(openssl rand -base64 32)"
NEXTAUTH_SECRET="$(openssl rand -base64 32)"
NEXTAUTH_URL="http://151.80.52.16:3000"
EOL

# Initialize Prisma
print_status "Initializing Prisma..."
npx prisma generate || print_error "Failed to generate Prisma client"
npx prisma db push || print_error "Failed to push database schema"

# Build the application
print_status "Building the application..."
npm run build || print_error "Failed to build the application"

# Set up PM2 ecosystem file
print_status "Creating PM2 ecosystem file..."
cat > ecosystem.config.js << EOL
module.exports = {
  apps: [{
    name: 'next-app',
    script: 'npm',
    args: 'start',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    watch: false,
    max_memory_restart: '1G',
    restart_delay: 3000,
    max_restarts: 10
  }]
}
EOL

# Start the application with PM2
print_status "Starting the application..."
pm2 start ecosystem.config.js || print_error "Failed to start the application"
pm2 save || print_warning "Failed to save PM2 process list"
pm2 startup || print_warning "Failed to setup PM2 startup script"

# Set correct permissions
print_status "Setting correct permissions..."
chown -R www-data:www-data /var/www/next-app
chmod -R 755 /var/www/next-app

# Print completion message
echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "\nYour Next.js application is now running at:"
echo -e "${YELLOW}http://151.80.52.16:3000${NC}"
echo -e "\nDefault admin credentials:"
echo -e "Phone: ${YELLOW}09170434697${NC}"
echo -e "Password: ${YELLOW}admin123${NC}"
echo -e "\n${YELLOW}Troubleshooting Tips:${NC}"
echo "1. Check application logs: pm2 logs next-app"
echo "2. Check process status: pm2 status"
echo "3. Restart application: pm2 restart next-app"
echo "4. View PostgreSQL logs: tail -f /var/log/postgresql/postgresql-14-main.log"
echo "5. Check firewall status: ufw status"
echo "6. Monitor system resources: htop"
echo "7. Check Node.js version: node --version"
echo "8. Check npm version: npm --version"
echo "9. Check database connection: psql -U nextuser -d nextdb -h localhost"
echo "10. View application error logs: tail -f /var/www/next-app/.next/error.log"