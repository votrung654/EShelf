// Simple script to check PostgreSQL connection
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkConnection() {
  try {
    await prisma.$connect();
    console.log('Database connection successful');
    await prisma.$disconnect();
    process.exit(0);
  } catch (error) {
    console.error('Database connection failed:', error.message);
    await prisma.$disconnect();
    process.exit(1);
  }
}

checkConnection();

