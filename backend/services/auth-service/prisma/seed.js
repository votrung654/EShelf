const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed process...\n');

  try {
    // Test database connection
    await prisma.$connect();
    console.log('✅ Database connected successfully\n');

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
    console.log('✅ Admin user created:', admin.email);

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
    console.log('✅ Demo user created:', demoUser.email);

    // Load book data from JSON
    const bookDataPath = path.join(__dirname, '../../../src/data/book-details.json');
    let bookData = [];
    
    try {
      if (fs.existsSync(bookDataPath)) {
        bookData = JSON.parse(fs.readFileSync(bookDataPath, 'utf8'));
        console.log(`\n📚 Found ${bookData.length} books in JSON`);
      } else {
        console.log('⚠️  Book data file not found, skipping books seed');
      }
    } catch (error) {
      console.error('⚠️  Error loading book data:', error.message);
    }

    // Create genres from book data
    if (bookData.length > 0) {
      const genreSet = new Set();
      bookData.forEach(book => {
        (book.genres || []).forEach(genre => genreSet.add(genre));
      });

      console.log(`\nCreating ${genreSet.size} genres...`);
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
      console.log(`✅ Created ${genreSet.size} genres`);

      // Create books (first 50 only)
      console.log(`\nCreating books (first 50)...`);
      let booksCreated = 0;
      for (const bookItem of bookData.slice(0, 50)) {
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
          booksCreated++;
        } catch (error) {
          console.error(`Error creating book ${bookItem.isbn}:`, error.message);
        }
      }
      console.log(`✅ Created ${booksCreated} books with genres`);
    }

    console.log('\n✅ Seeding completed successfully!\n');
    console.log('═══════════════════════════════════════════════════════');
    console.log('📋 LOGIN CREDENTIALS');
    console.log('═══════════════════════════════════════════════════════');
    console.log('\n👑 ADMIN ACCOUNT:');
    console.log('   Email:    admin@eshelf.com');
    console.log('   Password: Admin123!');
    console.log('   Role:     ADMIN');
    console.log('\n👤 USER ACCOUNT:');
    console.log('   Email:    user@eshelf.com');
    console.log('   Password: User123!');
    console.log('   Role:     USER');
    console.log('\n═══════════════════════════════════════════════════════\n');

  } catch (error) {
    console.error('\n❌ Seeding failed:', error);
    throw error;
  }
}

main()
  .catch((e) => {
    console.error('\n❌ Fatal error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    console.log('👋 Database connection closed\n');
  });


