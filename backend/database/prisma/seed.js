const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function main() {
  console.log('Starting seed process...\n');

  try {
    await prisma.$connect();
    console.log('Database connected successfully\n');

    // Create admin user
    console.log('Creating admin user...');
    const adminPassword = await bcrypt.hash('Admin123!', 12);
    const admin = await prisma.user.upsert({
      where: { email: 'admin@eshelf.com' },
      update: {
        passwordHash: adminPassword,
        role: 'ADMIN',
      },
      create: {
        email: 'admin@eshelf.com',
        username: 'admin',
        passwordHash: adminPassword,
        name: 'Administrator',
        role: 'ADMIN',
        emailVerified: true,
      },
    });
    console.log('Admin user created:', admin.email);

    // Create demo user
    console.log('Creating demo user...');
    const userPassword = await bcrypt.hash('User123!', 12);
    const demoUser = await prisma.user.upsert({
      where: { email: 'user@eshelf.com' },
      update: {
        passwordHash: userPassword,
        role: 'USER',
      },
      create: {
        email: 'user@eshelf.com',
        username: 'demouser',
        passwordHash: userPassword,
        name: 'Demo User',
        role: 'USER',
        emailVerified: true,
      },
    });
    console.log('Demo user created:', demoUser.email);

    // Load book data from JSON
    // Try multiple paths: container volume mount, then relative path
    const possiblePaths = [
      path.join(__dirname, '../data/book-details.json'), // Container volume mount
      path.join(__dirname, '../../../src/data/book-details.json'), // Relative from project root
      '/app/data/book-details.json' // Absolute path in container
    ];
    
    let bookData = [];
    let bookDataPath = null;
    
    for (const testPath of possiblePaths) {
      if (fs.existsSync(testPath)) {
        bookDataPath = testPath;
        break;
      }
    }
    
    try {
      if (bookDataPath && fs.existsSync(bookDataPath)) {
        bookData = JSON.parse(fs.readFileSync(bookDataPath, 'utf8'));
        console.log(`\nFound ${bookData.length} books in JSON at ${bookDataPath}`);
      } else {
        console.log('Book data file not found, skipping books seed');
        console.log('Tried paths:', possiblePaths.join(', '));
      }
    } catch (error) {
      console.error('Error loading book data:', error.message);
    }

    // Check if books already exist in database
    const existingBooksCount = await prisma.book.count();
    console.log(`\nExisting books in database: ${existingBooksCount}`);

    // Create books and genres
    if (bookData.length > 0) {
      // Seed ALL books, not just 50
      const booksToCreate = bookData;
      const genreSet = new Set();
      
      // Collect genres from all books
      booksToCreate.forEach(book => {
        (book.genres || []).forEach(genre => genreSet.add(genre));
      });

      console.log(`\nProcessing ${genreSet.size} genres from ${booksToCreate.length} books...`);
      
      // Create genres first
      let genresCreated = 0;
      let genresUpdated = 0;
      for (const genreName of genreSet) {
        const slug = genreName.toLowerCase()
          .replace(/\s+/g, '-')
          .replace(/[^\w-]/g, '');
        
        const existingGenre = await prisma.genre.findUnique({ where: { name: genreName } });
        if (!existingGenre) {
          await prisma.genre.create({
            data: {
              name: genreName,
              slug,
            },
          });
          genresCreated++;
        } else {
          genresUpdated++;
        }
      }
      console.log(`Genres: ${genresCreated} created, ${genresUpdated} already exist`);

      // Create books
      console.log(`\nProcessing ${booksToCreate.length} books...`);
      let booksCreated = 0;
      let booksSkipped = 0;
      
      for (const bookItem of booksToCreate) {
        try {
          const existingBook = await prisma.book.findUnique({ where: { isbn: bookItem.isbn } });
          
          if (existingBook) {
            // Book already exists, skip to preserve existing data
            booksSkipped++;
            continue;
          }
          
          // Create new book
          const book = await prisma.book.create({
            data: {
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
              const existingLink = await prisma.bookGenre.findUnique({
                where: {
                  bookId_genreId: { bookId: book.id, genreId: genre.id }
                },
              });
              
              if (!existingLink) {
                await prisma.bookGenre.create({
                  data: {
                    bookId: book.id,
                    genreId: genre.id,
                  },
                });
              }
            }
          }
          booksCreated++;
        } catch (error) {
          console.error(`Error creating book ${bookItem.isbn}:`, error.message);
        }
      }
      
      const finalBooksCount = await prisma.book.count();
      console.log(`\nBooks: ${booksCreated} created, ${booksSkipped} skipped (already exist)`);
      console.log(`Total books in database: ${finalBooksCount}`);
    } else {
      console.log('\nNo book data to seed. Database will keep existing books.');
    }

    console.log('\nSeeding completed successfully!\n');
    console.log('===================================================');
    console.log('LOGIN CREDENTIALS');
    console.log('===================================================');
    console.log('\nADMIN ACCOUNT:');
    console.log('   Email:    admin@eshelf.com');
    console.log('   Password: Admin123!');
    console.log('   Role:     ADMIN');
    console.log('\nUSER ACCOUNT:');
    console.log('   Email:    user@eshelf.com');
    console.log('   Password: User123!');
    console.log('   Role:     USER');
    console.log('\n===================================================\n');

  } catch (error) {
    console.error('\nSeeding failed:', error);
    throw error;
  }
}

main()
  .catch((e) => {
    console.error('\nFatal error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    console.log('Database connection closed\n');
  });


