# Prisma 7 Best Practices

This guide provides comprehensive best practices for using Prisma ORM 7 to build efficient, type-safe, and maintainable database applications. Follow these guidelines for schema modeling, migrations, queries, and production deployment.

> **Note**: This guide is updated for Prisma 7, which introduces breaking changes including the new `prisma-client` generator, required driver adapters, and `prisma.config.ts` for CLI configuration.

## Table of Contents

- [Core Principles](#core-principles)
- [Prisma 7 Configuration](#prisma-7-configuration)
- [Schema Modeling](#schema-modeling)
- [Type Safety](#type-safety)
- [Query Optimization](#query-optimization)
- [Migrations](#migrations)
- [Transactions](#transactions)
- [Performance Optimization](#performance-optimization)
- [Testing](#testing)
- [Security](#security)
- [Production Deployment](#production-deployment)

## Core Principles

### Type-Safe Database Access

**Always leverage Prisma's generated types** for compile-time safety and autocomplete.

```typescript
// Prisma 7: Import from your custom output path (with /client suffix)
import { PrismaClient, User, Post } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

// Prisma 7 requires a driver adapter
const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL })
const prisma = new PrismaClient({ adapter })

// ✅ Type-safe query - TypeScript knows the return type
const user: User = await prisma.user.findUnique({
  where: { id: 1 }
})

// ✅ TypeScript catches errors at compile time
const post = await prisma.post.create({
  data: {
    title: 'Hello World',
    // TypeScript error: Property 'invalid' does not exist
    // invalid: 'field'
  }
})
```

### Use `typeof` for PrismaClient Parameters

**Optimize TypeScript performance** by using `typeof` instead of direct type references.

❌ **Problematic (high memory, slow compilation):**
```typescript
import { PrismaClient } from '@/generated/prisma/client'

async function saveUser(prisma: PrismaClient) {
  // This causes extensive type expansion
}
```

✅ **Optimized (fast compilation, low memory):**
```typescript
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL })
const prisma = new PrismaClient({ adapter })

async function saveUser(db: typeof prisma) {
  // Uses type query - much faster
}

await saveUser(prisma)
```

### Server-First Architecture

Use Prisma in Server Components and Server Actions (Next.js 16).

```typescript
// app/actions/user.ts
'use server'

import prisma from '@/lib/prisma'

export async function getUser(id: number) {
  return await prisma.user.findUnique({
    where: { id }
  })
}
```

## Prisma 7 Configuration

### Generator Configuration

Prisma 7 introduces the new `prisma-client` generator (replacing `prisma-client-js`). The `output` field is now **required**.

```prisma
// schema.prisma
generator client {
  provider = "prisma-client"        // New provider (replaces prisma-client-js)
  output   = "../src/generated/prisma" // Required: custom output path

  // Optional fields with defaults
  runtime                = "nodejs"   // nodejs | deno | bun | workerd | vercel-edge | react-native
  moduleFormat           = "esm"      // esm | cjs (inferred from tsconfig)
  generatedFileExtension = "ts"       // ts | mts | cts
  importFileExtension    = "ts"       // ts | mts | cts | js | mjs | cjs | ""
}

datasource db {
  provider = "postgresql"
  // Note: url is now configured in prisma.config.ts
}
```

### prisma.config.ts

Prisma 7 uses a TypeScript configuration file for CLI settings. Create `prisma.config.ts` in your project root:

```typescript
// prisma.config.ts
import 'dotenv/config'
import { defineConfig, env } from 'prisma/config'

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',  // Optional: replaces prisma.seed in package.json
  },
  datasource: {
    url: env('DATABASE_URL'),
    shadowDatabaseUrl: env('SHADOW_DATABASE_URL'),  // Optional
  },
})
```

### Driver Adapters (Required in Prisma 7)

Prisma 7 requires driver adapters for database connections. Install the adapter for your database:

```bash
# PostgreSQL
pnpm add @prisma/adapter-pg pg
pnpm add -D @types/pg

# MySQL
pnpm add @prisma/adapter-mysql mysql2

# SQLite (LibSQL/Turso)
pnpm add @prisma/adapter-libsql @libsql/client

# Prisma Postgres (managed)
pnpm add @prisma/adapter-ppg
```

### Prisma Client Singleton (Next.js)

The recommended singleton pattern for Next.js with Prisma 7:

```typescript
// lib/prisma.ts
import { PrismaClient } from '@/generated/prisma/client'  // Must include /client
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL!,
})

const globalForPrisma = global as unknown as { prisma: PrismaClient }

const prisma = globalForPrisma.prisma || new PrismaClient({ adapter })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

export default prisma
```

> **Critical**: Always import from `@/generated/prisma/client` (with `/client` suffix). Importing without `/client` will break your application.

### Import Changes from Prisma 6

```typescript
// ❌ Old (Prisma 6 and earlier)
import { PrismaClient } from '@prisma/client'

// ✅ New (Prisma 7)
import { PrismaClient } from '@/generated/prisma/client'
// or
import { PrismaClient } from '../generated/prisma/client'
```

## Schema Modeling

### Model Naming Conventions

```prisma
// ✅ Use PascalCase for models
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  firstName String   // camelCase for fields
  lastName  String
  posts     Post[]   // plural for relations
  profile   Profile? // singular for one-to-one
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String   @db.VarChar(255) // Specify DB type for strings
  content   String?  // ? for optional fields
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
  tags      Tag[]    // many-to-many relation

  @@index([authorId]) // Add index for foreign keys
}

model Profile {
  id     Int    @id @default(autoincrement())
  bio    String?
  user   User   @relation(fields: [userId], references: [id])
  userId Int    @unique // Unique for one-to-one

  @@index([userId])
}

model Tag {
  id    Int    @id @default(autoincrement())
  name  String @unique
  posts Post[]
}
```

### Field Best Practices

**Always specify string lengths** to optimize database storage:

```prisma
model User {
  id       Int    @id @default(autoincrement())
  email    String @unique @db.VarChar(255)
  name     String @db.VarChar(100)
  bio      String? @db.Text // Use Text for long content
  code     String @db.Char(6) // Fixed-length codes
}
```

**Use appropriate field types:**

```prisma
model Product {
  id          Int      @id @default(autoincrement())
  name        String   @db.VarChar(255)
  price       Decimal  @db.Decimal(10, 2) // For currency
  quantity    Int
  available   Boolean  @default(true)
  metadata    Json?    // For flexible data
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  publishedAt DateTime?
}
```

### Relations

**One-to-Many:**
```prisma
model User {
  id    Int    @id @default(autoincrement())
  posts Post[]
}

model Post {
  id       Int  @id @default(autoincrement())
  author   User @relation(fields: [authorId], references: [id])
  authorId Int

  @@index([authorId])
}
```

**One-to-One:**
```prisma
model User {
  id      Int      @id @default(autoincrement())
  profile Profile?
}

model Profile {
  id     Int  @id @default(autoincrement())
  user   User @relation(fields: [userId], references: [id])
  userId Int  @unique

  @@index([userId])
}
```

**Many-to-Many (Implicit):**
```prisma
model Post {
  id   Int   @id @default(autoincrement())
  tags Tag[]
}

model Tag {
  id    Int    @id @default(autoincrement())
  posts Post[]
}
// Prisma creates _PostToTag join table automatically
```

**Many-to-Many (Explicit - when you need extra fields):**
```prisma
model Post {
  id         Int            @id @default(autoincrement())
  categories PostCategory[]
}

model Category {
  id    Int            @id @default(autoincrement())
  posts PostCategory[]
}

model PostCategory {
  post       Post     @relation(fields: [postId], references: [id])
  postId     Int
  category   Category @relation(fields: [categoryId], references: [id])
  categoryId Int
  assignedAt DateTime @default(now()) // Extra field

  @@id([postId, categoryId])
  @@index([postId])
  @@index([categoryId])
}
```

### Indexes and Performance

**Add indexes for:**
- Foreign keys
- Fields used in WHERE clauses
- Fields used in ORDER BY
- Unique constraints

```prisma
model Post {
  id        Int      @id @default(autoincrement())
  title     String   @db.VarChar(255)
  authorId  Int
  published Boolean  @default(false)
  createdAt DateTime @default(now())

  @@index([authorId]) // Foreign key
  @@index([published]) // Frequently queried
  @@index([createdAt(sort: Desc)]) // Sorted queries
  @@index([authorId, published]) // Composite index
  @@unique([title, authorId]) // Unique constraint
}
```

### Enums

Use enums for fixed sets of values:

```prisma
enum Role {
  USER
  ADMIN
  MODERATOR
}

enum Status {
  DRAFT
  PUBLISHED
  ARCHIVED
}

model User {
  id     Int    @id @default(autoincrement())
  email  String @unique
  role   Role   @default(USER)
  status Status @default(DRAFT)
}
```

## Type Safety

### Generated Types

**Always use Prisma's generated types:**

```typescript
import { Prisma, User, Post } from '@/generated/prisma/client'

// ✅ Use generated model types
function formatUser(user: User): string {
  return `${user.name} (${user.email})`
}

// ✅ Use generated input types
const createData: Prisma.UserCreateInput = {
  email: 'user@example.com',
  name: 'John Doe',
  posts: {
    create: [
      { title: 'First Post', content: 'Hello World' }
    ]
  }
}
```

### Partial Types with Prisma Validator

**Create type-safe partial types** using `Prisma.validator`:

```typescript
import { Prisma } from '@/generated/prisma/client'

// Define reusable query configurations
const userWithPosts = Prisma.validator<Prisma.UserDefaultArgs>()({
  include: { posts: true },
})

const userPersonalData = Prisma.validator<Prisma.UserDefaultArgs>()({
  select: {
    email: true,
    name: true,
    profile: {
      select: { bio: true }
    }
  },
})

// Extract types from configurations
type UserWithPosts = Prisma.UserGetPayload<typeof userWithPosts>
type UserPersonalData = Prisma.UserGetPayload<typeof userPersonalData>

// Use in functions
async function getUserWithPosts(id: number): Promise<UserWithPosts | null> {
  return await prisma.user.findUnique({
    where: { id },
    ...userWithPosts,
  })
}
```

### Type-Safe Query Building

```typescript
import { Prisma } from '@/generated/prisma/client'

// Build select object with type safety
const userSelect: Prisma.UserSelect = {
  id: true,
  email: true,
  name: true,
  // TypeScript provides autocomplete and validation
}

// Build include object
const postInclude: Prisma.PostInclude = {
  author: true,
  tags: true,
}

// Use in queries
const user = await prisma.user.findUnique({
  where: { id: 1 },
  select: userSelect,
})

const posts = await prisma.post.findMany({
  include: postInclude,
})
```

## Query Optimization

### Select Only What You Need

❌ **Bad (fetches all fields):**
```typescript
const users = await prisma.user.findMany()
// Returns: { id, email, name, password, createdAt, updatedAt, ... }
```

✅ **Good (select specific fields):**
```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
  }
})
// Returns: { id, email, name }
```

### Optimize Relations with Select/Include

❌ **Bad (N+1 query problem):**
```typescript
const posts = await prisma.post.findMany()

for (const post of posts) {
  // This creates N additional queries!
  const author = await prisma.user.findUnique({
    where: { id: post.authorId }
  })
}
```

✅ **Good (single query with join):**
```typescript
const posts = await prisma.post.findMany({
  include: {
    author: {
      select: {
        id: true,
        name: true,
        email: true,
      }
    }
  }
})
// Single query with JOIN
```

### Pagination

**Use cursor-based pagination for large datasets:**

```typescript
// Cursor-based (efficient for large datasets)
async function getPaginatedPosts(cursor?: number, limit = 10) {
  return await prisma.post.findMany({
    take: limit,
    skip: cursor ? 1 : 0,
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { createdAt: 'desc' },
  })
}

// Offset-based (simpler, but slower for large offsets)
async function getPostsPage(page = 1, limit = 10) {
  const skip = (page - 1) * limit

  const [posts, total] = await Promise.all([
    prisma.post.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
    }),
    prisma.post.count()
  ])

  return {
    posts,
    total,
    pages: Math.ceil(total / limit),
  }
}
```

### Filtering and Searching

```typescript
// Complex filtering
const posts = await prisma.post.findMany({
  where: {
    AND: [
      { published: true },
      {
        OR: [
          { title: { contains: searchTerm, mode: 'insensitive' } },
          { content: { contains: searchTerm, mode: 'insensitive' } },
        ]
      },
      {
        author: {
          role: 'ADMIN'
        }
      }
    ]
  },
  orderBy: [
    { createdAt: 'desc' },
    { title: 'asc' }
  ]
})

// Advanced filtering with relations
const users = await prisma.user.findMany({
  where: {
    posts: {
      some: { // At least one post matches
        published: true,
        views: { gte: 100 }
      }
    }
  }
})
```

### Aggregations

```typescript
// Count
const publishedCount = await prisma.post.count({
  where: { published: true }
})

// Aggregate functions
const stats = await prisma.post.aggregate({
  where: { published: true },
  _count: true,
  _avg: { views: true },
  _sum: { views: true },
  _max: { views: true },
  _min: { views: true },
})

// Group by
const postsByAuthor = await prisma.post.groupBy({
  by: ['authorId'],
  _count: {
    id: true,
  },
  _avg: {
    views: true,
  },
  where: {
    published: true
  }
})
```

### Avoid CHAR Type in PostgreSQL

❌ **Bad (performance issue in PostgreSQL):**
```prisma
model Item {
  id   Int    @id @default(autoincrement())
  code String @db.Char(10) // Avoid CHAR - causes padding issues
}
```

✅ **Good (use VARCHAR instead):**
```prisma
model Item {
  id   Int    @id @default(autoincrement())
  code String @db.VarChar(10) // Better performance
}
```

## Migrations

### Development Workflow

**1. Create migration:**
```bash
npx prisma migrate dev --name add_user_profile
```

This will:
- Generate SQL migration files
- Apply migration to database
- Regenerate Prisma Client

**2. Review generated SQL:**
```sql
-- CreateTable
CREATE TABLE "Profile" (
    "id" SERIAL NOT NULL,
    "bio" TEXT,
    "userId" INTEGER NOT NULL,

    CONSTRAINT "Profile_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Profile_userId_key" ON "Profile"("userId");

-- AddForeignKey
ALTER TABLE "Profile" ADD CONSTRAINT "Profile_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
```

**3. Commit migration files:**
```bash
git add prisma/migrations
git commit -m "feat: add user profile"
```

### Production Deployment

**Apply migrations in production:**

```bash
# In CI/CD pipeline or deployment script
npx prisma migrate deploy
```

**Generate Prisma Client:**
```bash
npx prisma generate
```

**Example Docker setup:**
```dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci
RUN npx prisma generate

COPY . .
RUN npm run build

CMD ["sh", "-c", "npx prisma migrate deploy && npm start"]
```

### Migration Best Practices

**1. Always review generated SQL** before applying to production

**2. Create migrations in feature branches:**
```bash
git checkout -b feature/add-tags
# Make schema changes
npx prisma migrate dev --name add_tags
```

**3. Handle data migrations separately:**
```typescript
// prisma/data-migration.ts
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! })
const prisma = new PrismaClient({ adapter })

async function main() {
  // Migrate existing data
  await prisma.$executeRaw`
    UPDATE "User"
    SET "status" = 'ACTIVE'
    WHERE "status" IS NULL
  `
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
```

**4. Test migrations locally:**
```bash
# Reset database
npx prisma migrate reset

# Re-apply all migrations
npx prisma migrate dev
```

### Schema Changes Without Breaking Production

**Adding nullable fields (safe):**
```prisma
model User {
  id       Int     @id @default(autoincrement())
  email    String  @unique
  bio      String? // ✅ Safe: nullable field
}
```

**Adding required fields (requires data migration):**
```prisma
model User {
  id     Int    @id @default(autoincrement())
  email  String @unique
  status String @default("ACTIVE") // ✅ Safe: has default
}
```

**Renaming fields (requires two-step migration):**
```bash
# Step 1: Add new field
# Step 2: Copy data
# Step 3: Remove old field (in separate deployment)
```

## Transactions

### Array Transactions (Preferred for Independent Operations)

**More cost-efficient** - counts as single operation:

```typescript
await prisma.$transaction([
  prisma.user.create({
    data: { name: 'Alice', email: 'alice@example.com' }
  }),
  prisma.post.create({
    data: { title: 'Hello', authorId: 1 }
  }),
])
```

### Interactive Transactions (For Dependent Operations)

Use when queries depend on previous results:

```typescript
await prisma.$transaction(async (tx) => {
  // Create user
  const user = await tx.user.create({
    data: {
      name: 'Alice',
      email: 'alice@example.com'
    }
  })

  // Use user.id in next query
  const post = await tx.post.create({
    data: {
      title: 'First Post',
      authorId: user.id // Depends on previous result
    }
  })

  // Update user stats
  await tx.user.update({
    where: { id: user.id },
    data: { postCount: { increment: 1 } }
  })

  return { user, post }
})
```

### Transaction Best Practices

**1. Keep transactions short:**
```typescript
// ❌ Bad: Long-running transaction
await prisma.$transaction(async (tx) => {
  const users = await tx.user.findMany()

  // Long processing...
  for (const user of users) {
    await processUser(user) // Might take minutes!
  }
})

// ✅ Good: Quick transaction
await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUnique({ where: { id } })

  if (!user) throw new Error('User not found')

  return await tx.user.update({
    where: { id },
    data: { balance: { decrement: amount } }
  })
})
```

**2. Set appropriate timeout:**
```typescript
await prisma.$transaction(
  async (tx) => {
    // Your operations
  },
  {
    maxWait: 5000, // Wait max 5s to start transaction
    timeout: 10000, // Transaction max duration 10s
  }
)
```

**3. Handle errors properly:**
```typescript
try {
  await prisma.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: { email: 'user@example.com' }
    })

    if (!isValid(user)) {
      throw new Error('Invalid user data')
    }

    await tx.profile.create({
      data: { userId: user.id, bio: 'New user' }
    })
  })
} catch (error) {
  // Transaction automatically rolled back
  console.error('Transaction failed:', error)
  throw error
}
```

## Performance Optimization

### Connection Pooling

**Configure connection limits:**

```prisma
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")

  // Connection pool settings
  relationMode = "prisma"
}
```

**Set in DATABASE_URL:**
```env
DATABASE_URL="postgresql://user:password@localhost:5432/mydb?connection_limit=10&pool_timeout=20"
```

### Prisma Client Initialization

**Singleton pattern for Next.js with Prisma 7:**

```typescript
// lib/prisma.ts
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL!,
})

const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    adapter,
    log: process.env.NODE_ENV === 'development'
      ? ['query', 'error', 'warn']
      : ['error'],
  })

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma
}

export default prisma
```

### Query Performance Monitoring

**Enable query logging:**

```typescript
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! })

const prisma = new PrismaClient({
  adapter,
  log: [
    { emit: 'event', level: 'query' },
    { emit: 'event', level: 'error' },
    { emit: 'event', level: 'warn' },
  ],
})

prisma.$on('query', (e) => {
  console.log('Query: ' + e.query)
  console.log('Duration: ' + e.duration + 'ms')
})
```

### Caching Strategies

**Cache frequently accessed data:**

```typescript
import { cache } from 'react'

// Next.js 16 - per-request cache
export const getUser = cache(async (id: number) => {
  return await prisma.user.findUnique({
    where: { id }
  })
})

// Or use external cache (Redis)
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.REDIS_URL!,
  token: process.env.REDIS_TOKEN!,
})

export async function getCachedUser(id: number) {
  const cached = await redis.get<User>(`user:${id}`)

  if (cached) return cached

  const user = await prisma.user.findUnique({
    where: { id }
  })

  if (user) {
    await redis.set(`user:${id}`, user, { ex: 3600 }) // 1 hour
  }

  return user
}
```

### Batch Operations

**Use batch operations for better performance:**

```typescript
// ❌ Bad: Multiple individual inserts
for (const userData of users) {
  await prisma.user.create({ data: userData })
}

// ✅ Good: Single batch insert
await prisma.user.createMany({
  data: users,
  skipDuplicates: true, // Ignore duplicate key errors
})

// Batch updates
await prisma.user.updateMany({
  where: { status: 'INACTIVE' },
  data: { deletedAt: new Date() }
})
```

### Raw Queries for Complex Operations

**Use raw SQL when Prisma queries are inefficient:**

```typescript
import { Prisma } from '@/generated/prisma/client'

// Raw query with type safety
const users = await prisma.$queryRaw<User[]>`
  SELECT * FROM "User"
  WHERE "createdAt" > NOW() - INTERVAL '7 days'
  ORDER BY "createdAt" DESC
  LIMIT 10
`

// With parameters (prevents SQL injection)
const email = 'user@example.com'
const user = await prisma.$queryRaw<User[]>`
  SELECT * FROM "User"
  WHERE "email" = ${email}
`

// Execute raw SQL (for updates/deletes)
await prisma.$executeRaw`
  UPDATE "User"
  SET "lastLogin" = NOW()
  WHERE "id" = ${userId}
`
```

## Testing

### Unit Testing

**Setup test database:**

```typescript
// tests/setup.ts
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_TEST_URL!,
})

const prisma = new PrismaClient({ adapter })

export async function setupTestDB() {
  await prisma.$connect()
}

export async function teardownTestDB() {
  await prisma.$disconnect()
}

export async function resetTestDB() {
  // Delete all data
  await prisma.post.deleteMany()
  await prisma.user.deleteMany()
}

export { prisma }
```

**Example test:**

```typescript
// tests/user.test.ts
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest'
import { prisma, setupTestDB, teardownTestDB, resetTestDB } from './setup'

beforeAll(async () => {
  await setupTestDB()
})

afterAll(async () => {
  await teardownTestDB()
})

beforeEach(async () => {
  await resetTestDB()
})

describe('User operations', () => {
  it('should create a user', async () => {
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User',
      },
    })

    expect(user.id).toBeDefined()
    expect(user.email).toBe('test@example.com')
  })

  it('should find user by email', async () => {
    await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User',
      },
    })

    const user = await prisma.user.findUnique({
      where: { email: 'test@example.com' },
    })

    expect(user).toBeDefined()
    expect(user?.name).toBe('Test User')
  })
})
```

### Integration Testing

**Test with real database:**

```typescript
// tests/integration/post.test.ts
import { describe, it, expect, beforeEach } from 'vitest'
import { prisma } from '../setup'

describe('Post operations', () => {
  let userId: number

  beforeEach(async () => {
    const user = await prisma.user.create({
      data: {
        email: 'author@example.com',
        name: 'Author',
      },
    })
    userId = user.id
  })

  it('should create post with author relation', async () => {
    const post = await prisma.post.create({
      data: {
        title: 'Test Post',
        content: 'Test Content',
        authorId: userId,
      },
      include: {
        author: true,
      },
    })

    expect(post.author.email).toBe('author@example.com')
  })
})
```

### Seeding Test Data

```typescript
// prisma/seed.ts
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! })
const prisma = new PrismaClient({ adapter })

async function main() {
  // Create test users
  const alice = await prisma.user.create({
    data: {
      email: 'alice@example.com',
      name: 'Alice',
      posts: {
        create: [
          {
            title: 'First Post',
            content: 'Hello World',
            published: true,
          },
          {
            title: 'Draft Post',
            content: 'Work in progress',
            published: false,
          },
        ],
      },
    },
  })

  console.log({ alice })
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
```

**Run seeding:**
```bash
npx prisma db seed
```

## Security

### Input Validation

**Always validate inputs with Zod:**

```typescript
import { z } from 'zod'

const createUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150).optional(),
})

export async function createUser(input: unknown) {
  // Validate input
  const data = createUserSchema.parse(input)

  // Create user
  return await prisma.user.create({
    data,
  })
}
```

### Prevent SQL Injection

**Prisma automatically prevents SQL injection:**

```typescript
// ✅ Safe: Prisma parameterizes queries
const user = await prisma.user.findUnique({
  where: { email: userInput } // Automatically sanitized
})

// ✅ Safe: Even with raw queries using template literals
const users = await prisma.$queryRaw<User[]>`
  SELECT * FROM "User"
  WHERE "email" = ${userInput}
` // Prisma sanitizes parameters

// ❌ NEVER do this (vulnerable to SQL injection):
const users = await prisma.$queryRawUnsafe(
  `SELECT * FROM "User" WHERE "email" = '${userInput}'`
)
```

### Row-Level Security (RLS)

**Implement authorization checks:**

```typescript
// lib/auth.ts
export async function getUserPosts(userId: number, requesterId: number) {
  // Check authorization
  if (userId !== requesterId) {
    throw new Error('Unauthorized')
  }

  return await prisma.post.findMany({
    where: {
      authorId: userId,
    }
  })
}

// Or use middleware
export async function getPostWithAuth(postId: number, userId: number) {
  const post = await prisma.post.findUnique({
    where: { id: postId },
    include: { author: true }
  })

  if (!post) throw new Error('Post not found')

  // Check ownership
  if (post.authorId !== userId) {
    throw new Error('Not authorized to view this post')
  }

  return post
}
```

### Password Hashing

**Always hash passwords:**

```typescript
import bcrypt from 'bcrypt'

export async function createUserWithPassword(
  email: string,
  password: string
) {
  // Hash password
  const hashedPassword = await bcrypt.hash(password, 12)

  return await prisma.user.create({
    data: {
      email,
      password: hashedPassword,
    },
    select: {
      id: true,
      email: true,
      // Don't return password
    }
  })
}

export async function verifyPassword(
  email: string,
  password: string
) {
  const user = await prisma.user.findUnique({
    where: { email },
    select: {
      id: true,
      email: true,
      password: true,
    }
  })

  if (!user) return null

  const valid = await bcrypt.compare(password, user.password)

  if (!valid) return null

  // Don't return password
  const { password: _, ...userWithoutPassword } = user
  return userWithoutPassword
}
```

### Environment Variables

**Never commit sensitive data:**

```env
# .env (add to .gitignore)
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"

# .env.example (commit this)
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"
```

## Production Deployment

### Environment Setup

**Configure production database:**

```env
# Production
DATABASE_URL="postgresql://user:password@prod-db.example.com:5432/mydb?connection_limit=10&pool_timeout=20&sslmode=require"

# Enable connection pooling (recommended)
DATABASE_POOL_URL="postgresql://user:password@pooler.example.com:5432/mydb"
```

### Health Checks

**Database connectivity check:**

```typescript
// app/api/health/route.ts
import prisma from '@/lib/prisma'
import { NextResponse } from 'next/server'

export async function GET() {
  try {
    await prisma.$queryRaw`SELECT 1`

    return NextResponse.json({
      status: 'healthy',
      database: 'connected'
    })
  } catch (error) {
    return NextResponse.json(
      {
        status: 'unhealthy',
        database: 'disconnected',
        error: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 503 }
    )
  }
}
```

### Monitoring

**Log slow queries:**

```typescript
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! })

const prisma = new PrismaClient({
  adapter,
  log: [
    {
      emit: 'event',
      level: 'query',
    },
  ],
})

prisma.$on('query', (e) => {
  if (e.duration > 1000) {
    console.warn('Slow query detected:', {
      query: e.query,
      duration: `${e.duration}ms`,
      params: e.params,
    })
  }
})
```

### Graceful Shutdown

**Disconnect properly:**

```typescript
// lib/prisma.ts
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! })
const prisma = new PrismaClient({ adapter })

export default prisma

// Handle graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect()
  process.exit(0)
})

process.on('SIGTERM', async () => {
  await prisma.$disconnect()
  process.exit(0)
})
```

## Quality Checklist

Before deploying to production, verify:

### Prisma 7 Setup
- [ ] **Generator**: Using `prisma-client` provider with `output` path defined
- [ ] **Driver Adapter**: Installed and configured (e.g., `@prisma/adapter-pg`)
- [ ] **Config File**: `prisma.config.ts` created with datasource configuration
- [ ] **Imports**: All imports use custom output path with `/client` suffix

### General
- [ ] **Type Safety**: All queries use generated Prisma types
- [ ] **Schema Validation**: Schema changes reviewed and tested
- [ ] **Indexes**: Appropriate indexes on foreign keys and queried fields
- [ ] **Query Optimization**: Using select/include to fetch only needed data
- [ ] **Migrations**: All migrations tested and committed to version control
- [ ] **Error Handling**: Proper try-catch blocks and error messages
- [ ] **Testing**: Unit and integration tests for all database operations
- [ ] **Security**: Input validation, password hashing, authorization checks
- [ ] **Connection Pooling**: Configured for production workload
- [ ] **Monitoring**: Logging and health checks in place
- [ ] **Documentation**: Schema and models documented
- [ ] **Backups**: Database backup strategy implemented

## Resources

### Official Documentation
- [Prisma Documentation](https://www.prisma.io/docs)
- [Prisma Schema Reference](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference)
- [Prisma Client API](https://www.prisma.io/docs/reference/api-reference/prisma-client-reference)
- [Upgrade to Prisma 7](https://www.prisma.io/docs/orm/more/upgrade-guides/upgrading-versions/upgrading-to-prisma-7)
- [Driver Adapters](https://www.prisma.io/docs/orm/overview/databases/database-drivers)
- [Prisma Config Reference](https://www.prisma.io/docs/orm/reference/prisma-config-reference)

---

**Remember:** Prisma 7 requires driver adapters and a custom output path. Always import from your generated client path with the `/client` suffix. Review generated SQL and optimize queries for production workloads.
