const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create admin user
  const adminPassword = await bcrypt.hash('Admin123!', 12);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@eshelf.com' },
    update: {},
    create: {
      email: 'admin@eshelf.com',
      username: 'admin',
      passwordHash: adminPassword,
      name: 'Administrator',
      role: 'ADMIN',
      emailVerified: true,
    },
  });
  console.log('Created admin user:', admin.email);

  // Create demo user
  const userPassword = await bcrypt.hash('User123!', 12);
  const demoUser = await prisma.user.upsert({
    where: { email: 'user@eshelf.com' },
    update: {},
    create: {
      email: 'user@eshelf.com',
      username: 'demouser',
      passwordHash: userPassword,
      name: 'Demo User',
      role: 'USER',
      emailVerified: true,
    },
  });
  console.log('Created demo user:', demoUser.email);

  // Load book data from JSON
  const bookDataPath = path.join(__dirname, '../../../src/data/book-details.json');
  let bookData = [];
  
  try {
    if (fs.existsSync(bookDataPath)) {
      bookData = JSON.parse(fs.readFileSync(bookDataPath, 'utf8'));
      console.log(`Found ${bookData.length} books in JSON`);
    }
  } catch (error) {
    console.error('Error loading book data:', error);
  }

  // Create genres from book data
  const genreSet = new Set();
  bookData.forEach(book => {
    (book.genres || []).forEach(genre => genreSet.add(genre));
  });

  for (const genreName of genreSet) {
    const slug = genreName.toLowerCase()
      .replace(/\s+/g, '-')
      .replace(/[^\w-]/g, '');
    
    await prisma.genre.upsert({
      where: { name: genreName },
      update: {},
      create: {
        name: genreName,
        slug,
      },
    });
  }
  console.log(`Created ${genreSet.size} genres`);

  // Create books
  for (const bookItem of bookData.slice(0, 50)) { // Limit to 50 for initial seed
    try {
      const book = await prisma.book.upsert({
        where: { isbn: bookItem.isbn },
        update: {},
        create: {
          isbn: bookItem.isbn,
          title: bookItem.title,
          description: bookItem.description,
          authors: bookItem.author || [],
          translators: bookItem.translator || [],
          publisher: bookItem.publisher,
          coverUrl: bookItem.coverUrl,
          pdfUrl: bookItem.pdfUrl,
          pageCount: bookItem.pages,
          language: bookItem.language || 'vi',
          publishedYear: bookItem.year,
          extension: bookItem.extension,
          fileSize: bookItem.size,
        },
      });

      // Link genres
      for (const genreName of (bookItem.genres || [])) {
        const genre = await prisma.genre.findUnique({ where: { name: genreName } });
        if (genre) {
          await prisma.bookGenre.upsert({
            where: {
              bookId_genreId: { bookId: book.id, genreId: genre.id }
            },
            update: {},
            create: {
              bookId: book.id,
              genreId: genre.id,
            },
          });
        }
      }
    } catch (error) {
      console.error(`Error creating book ${bookItem.isbn}:`, error.message);
    }
  }
  console.log('Created books with genres');

  console.log('Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


