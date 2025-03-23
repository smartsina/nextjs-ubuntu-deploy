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

# State file to track progress
STATE_FILE="/var/www/next-app/.setup_state"

# Function to check if a step has been completed
check_step() {
    if [ -f "$STATE_FILE" ]; then
        grep -q "^$1=done$" "$STATE_FILE" && return 0
    fi
    return 1
}

# Function to mark a step as completed
mark_step_done() {
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$1=done" >> "$STATE_FILE"
}

# Function to check if PostgreSQL database exists
check_db_exists() {
    sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$1"
}

# Function to check if PostgreSQL user exists
check_user_exists() {
    sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$1'" | grep -q 1
}

# Update system packages if not done
if ! check_step "system_update"; then
    print_status "Updating system packages..."
    apt update && apt upgrade -y || print_error "Failed to update system packages"
    mark_step_done "system_update"
else
    print_status "System packages already updated"
fi

# Install required packages if not done
if ! check_step "required_packages"; then
    print_status "Installing required packages..."
    apt install -y curl git build-essential || print_error "Failed to install required packages"
    mark_step_done "required_packages"
else
    print_status "Required packages already installed"
fi

# Install Node.js 18.x if not done
if ! check_step "nodejs_install" && ! command -v node &> /dev/null; then
    print_status "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs || print_error "Failed to install Node.js"
    mark_step_done "nodejs_install"
else
    print_status "Node.js already installed"
fi

# Install PM2 globally if not done
if ! check_step "pm2_install" && ! command -v pm2 &> /dev/null; then
    print_status "Installing PM2..."
    npm install -g pm2 || print_error "Failed to install PM2"
    mark_step_done "pm2_install"
else
    print_status "PM2 already installed"
fi

# Install PostgreSQL if not done
if ! check_step "postgresql_install" && ! command -v psql &> /dev/null; then
    print_status "Installing PostgreSQL..."
    apt install -y postgresql postgresql-contrib || print_error "Failed to install PostgreSQL"
    mark_step_done "postgresql_install"
else
    print_status "PostgreSQL already installed"
fi

# Configure PostgreSQL if not done
if ! check_step "postgresql_config"; then
    print_status "Configuring PostgreSQL..."
    if ! check_user_exists "nextuser"; then
        sudo -u postgres psql -c "CREATE USER nextuser WITH PASSWORD 'nextpass123';" || print_warning "Failed to create user"
    else
        print_warning "PostgreSQL user 'nextuser' already exists"
    fi
    
    if ! check_db_exists "nextdb"; then
        sudo -u postgres psql -c "CREATE DATABASE nextdb OWNER nextuser;" || print_warning "Failed to create database"
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextdb TO nextuser;" || print_warning "Failed to grant privileges"
    else
        print_warning "Database 'nextdb' already exists"
    fi
    mark_step_done "postgresql_config"
else
    print_status "PostgreSQL already configured"
fi

# Configure firewall if not done
if ! check_step "firewall_config"; then
    print_status "Configuring firewall..."
    ufw allow 22/tcp # SSH
    ufw allow 80/tcp # HTTP
    ufw allow 443/tcp # HTTPS
    ufw allow 3000/tcp # Next.js app
    ufw --force enable
    mark_step_done "firewall_config"
else
    print_status "Firewall already configured"
fi

# Create project directory if it doesn't exist
if [ ! -d "/var/www/next-app" ]; then
    print_status "Creating project directory..."
    mkdir -p /var/www/next-app
fi

# Navigate to project directory
cd /var/www/next-app || print_error "Failed to access project directory"

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p src/app/lib

# Check if project is already installed
if [ -f "package.json" ] && [ -d "node_modules" ] && [ -d ".next" ]; then
    print_warning "Project appears to be already installed"
    read -p "Do you want to reinstall? This will backup your .env file and delete everything else. (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping reinstallation. Exiting..."
        exit 0
    fi
    
    # Backup .env file if it exists
    if [ -f ".env" ]; then
        print_status "Backing up .env file..."
        cp .env .env.backup
    fi
    
    # Clean existing installation
    print_status "Cleaning existing installation..."
    rm -rf * .[^.]*
    if [ -f ".env.backup" ]; then
        mv .env.backup .env
    fi
fi

# Create package.json if it doesn't exist
if [ ! -f "package.json" ]; then
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
    "@auth/core": "0.34.2",
    "@prisma/client": "^6.5.0",
    "@tabler/icons-react": "^2.40.0",
    "@tremor/react": "^3.11.1",
    "bcryptjs": "^2.4.3",
    "jose": "^5.2.0",
    "next": "14.0.4",
    "next-auth": "^4.24.11",
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
    "@eslint/config-array": "^2.1.0",
    "@eslint/object-schema": "^1.0.0",
    "eslint": "^8.57.0",
    "eslint-config-next": "14.0.4",
    "glob": "^10.3.10",
    "postcss": "^8",
    "prisma": "^6.5.0",
    "rimraf": "^5.0.5",
    "tailwindcss": "^3.3.0",
    "ts-node": "^10.9.1",
    "typescript": "^5"
  }
}
EOL
fi

# Create Prisma client singleton
print_status "Creating Prisma client singleton..."
cat > src/app/lib/prisma.ts << EOL
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
EOL

# Create SMS service
print_status "Creating SMS service..."
cat > src/app/lib/sms.ts << EOL
// This is a mock SMS service for development
// Replace with actual SMS service implementation in production

export async function sendSMS(phone: string, message: string): Promise<boolean> {
  if (process.env.NODE_ENV === 'development') {
    console.log(\`[Mock SMS] To: \${phone}, Message: \${message}\`);
    return true;
  }

  try {
    // TODO: Implement actual SMS service
    // Example:
    // const response = await fetch('SMS_API_URL', {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': \`Bearer \${process.env.SMS_API_KEY}\`
    //   },
    //   body: JSON.stringify({ phone, message })
    // });
    // return response.ok;
    
    return true;
  } catch (error) {
    console.error('SMS sending failed:', error);
    return false;
  }
}
EOL

# Clone or update repository
if [ ! -d ".git" ]; then
    print_status "Cloning the repository..."
    # Create temporary directory for cloning
    TEMP_DIR=$(mktemp -d)
    git clone https://github.com/smartsina/Physics-Practice.git "$TEMP_DIR" || print_error "Failed to clone repository"
    
    # Copy files from temp directory
    print_status "Copying project files..."
    cp -r "$TEMP_DIR"/* . || print_error "Failed to copy project files"
    cp -r "$TEMP_DIR"/.[!.]* . 2>/dev/null || print_warning "No hidden files to copy"
    rm -rf "$TEMP_DIR"
else
    print_status "Updating existing repository..."
    git pull origin main || print_warning "Failed to update repository"
fi

# Install project dependencies
print_status "Installing project dependencies..."
npm install --legacy-peer-deps || {
    print_warning "Failed to install with --legacy-peer-deps, trying with --force..."
    npm install --force || print_error "Failed to install project dependencies"
}

# Create or update .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file..."
    cat > .env << EOL
DATABASE_URL="postgresql://nextuser:nextpass123@localhost:5432/nextdb?schema=public"
NEXT_PUBLIC_API_URL="http://151.80.52.16:3000"
PORT=3000
JWT_SECRET="$(openssl rand -base64 32)"
NEXTAUTH_SECRET="$(openssl rand -base64 32)"
NEXTAUTH_URL="http://151.80.52.16:3000"
EOL
else
    print_warning ".env file already exists, skipping creation"
fi

# Initialize Prisma if not done
if ! check_step "prisma_init" || [ ! -d "node_modules/.prisma" ]; then
    print_status "Initializing Prisma..."
    npx prisma generate || print_error "Failed to generate Prisma client"
    npx prisma db push || print_error "Failed to push database schema"
    mark_step_done "prisma_init"
else
    print_status "Prisma already initialized"
fi

# Build the application
print_status "Building the application..."
npm run build || print_error "Failed to build the application"

# Set up PM2 ecosystem file
if [ ! -f "ecosystem.config.js" ]; then
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
fi

# Start or restart the application with PM2
if pm2 list | grep -q "next-app"; then
    print_status "Restarting the application..."
    pm2 restart next-app || print_error "Failed to restart the application"
else
    print_status "Starting the application..."
    pm2 start ecosystem.config.js || print_error "Failed to start the application"
fi

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
echo -e "\n${YELLOW}State file location:${NC} $STATE_FILE"
echo "You can delete this file to force a fresh installation of certain components."