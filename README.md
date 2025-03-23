# Next.js Ubuntu Deployment Script

This script automates the deployment of a Next.js application on Ubuntu 22.04 VPS. It handles all necessary setup including Node.js, PostgreSQL, and PM2 process manager.

## Quick Start

Connect to your VPS via SSH and run:

```bash
bash <(curl -s -L https://raw.githubusercontent.com/smartsina/nextjs-ubuntu-deploy/main/setup.sh)
```

## Prerequisites

- Ubuntu 22.04 VPS
- Root access or sudo privileges
- SSH access to your VPS

## What the Script Does

1. **System Updates**
   - Updates package list
   - Upgrades existing packages

2. **Installation**
   - Node.js 18.x
   - PostgreSQL
   - PM2 process manager
   - Git and build essentials

3. **Database Setup**
   - Creates PostgreSQL user and database
   - Configures database permissions

4. **Application Setup**
   - Clones the repository
   - Installs dependencies
   - Sets up environment variables
   - Initializes Prisma
   - Builds and starts the application

5. **Security**
   - Configures UFW firewall
   - Opens necessary ports (22, 80, 443, 3000)

## Manual Installation

If you prefer to run commands manually:

1. **Connect to your VPS:**
   ```bash
   ssh root@151.80.52.16
   ```

2. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/smartsina/nextjs-ubuntu-deploy/main/setup.sh
   ```

3. **Make it executable:**
   ```bash
   chmod +x setup.sh
   ```

4. **Run the script:**
   ```bash
   sudo ./setup.sh
   ```

## Access the Application

After successful deployment:

- Application URL: `http://151.80.52.16:3000`
- Admin credentials:
  - Phone: `09170434697`
  - Password: `admin123`

## Environment Variables

The script sets up the following environment variables:

```env
DATABASE_URL="postgresql://nextuser:nextpass123@localhost:5432/nextdb?schema=public"
NEXT_PUBLIC_API_URL="http://151.80.52.16:3000"
PORT=3000
JWT_SECRET=[randomly generated]
NEXTAUTH_SECRET=[randomly generated]
NEXTAUTH_URL="http://151.80.52.16:3000"
```

## Troubleshooting

1. **Application Issues**
   ```bash
   # View application logs
   pm2 logs next-app
   
   # Check process status
   pm2 status
   
   # Restart application
   pm2 restart next-app
   ```

2. **Database Issues**
   ```bash
   # Check PostgreSQL status
   systemctl status postgresql
   
   # View PostgreSQL logs
   tail -f /var/log/postgresql/postgresql-14-main.log
   ```

3. **Port Issues**
   ```bash
   # Check which process is using port 3000
   lsof -i :3000
   
   # Check firewall status
   ufw status
   ```

## Security Notes

1. Change default admin credentials after first login
2. Consider setting up SSL/TLS with Let's Encrypt
3. Regularly update system packages and dependencies
4. Monitor logs for suspicious activities

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - feel free to use and modify for your own projects.