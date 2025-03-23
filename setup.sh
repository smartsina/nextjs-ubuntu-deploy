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

# Clone the repository (replace with your actual repo URL)
print_status "Cloning the repository..."
git clone https://github.com/smartsina/Physics-Practice.git . || print_error "Failed to clone repository"

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

# Start the application with PM2
print_status "Starting the application..."
pm2 start npm --name "next-app" -- start || print_error "Failed to start the application"
pm2 save || print_warning "Failed to save PM2 process list"
pm2 startup || print_warning "Failed to setup PM2 startup script"

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