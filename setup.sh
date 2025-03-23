#!/bin/bash

# ... (previous code remains the same until the package.json creation) ...

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p src/app/lib

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

# ... (rest of the script remains the same) ...