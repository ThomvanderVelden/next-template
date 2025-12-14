# Prisma 7 Configuration

This project uses **Prisma 7** with PostgreSQL. For detailed Prisma documentation, use the Context7 MCP server (`mcp__context7__resolve-library-id` and `mcp__context7__get-library-docs`).

## Key Files

- `prisma/schema.prisma` - Database schema
- `prisma.config.ts` - CLI configuration (project root)
- `src/lib/prisma.ts` - Client singleton with driver adapter
- `src/generated/prisma/` - Generated Prisma client

## Commands

```bash
pnpm db:generate   # Generate Prisma client
pnpm db:migrate    # Run migrations
pnpm db:push       # Push schema changes
pnpm db:studio     # Open Prisma Studio
```

## Prisma 7 Breaking Changes

### 1. Import Path (Critical)

Always import from the custom output path with `/client` suffix:

```typescript
// ✅ Correct (Prisma 7)
import { PrismaClient, User } from '@/generated/prisma/client'

// ❌ Wrong (old Prisma 6 style - will break)
import { PrismaClient } from '@prisma/client'
```

### 2. Driver Adapter Required

Prisma 7 requires a driver adapter. This project uses `@prisma/adapter-pg`:

```typescript
import { PrismaClient } from '@/generated/prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! })
const prisma = new PrismaClient({ adapter })
```

### 3. Generator Configuration

The schema uses the new `prisma-client` generator (not `prisma-client-js`):

```prisma
generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"  // Required in Prisma 7
}
```

### 4. CLI Configuration

Database URL is configured in `prisma.config.ts`, not in the schema:

```typescript
// prisma.config.ts
import { defineConfig, env } from 'prisma/config'

export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: env('DATABASE_URL'),
  },
})
```

## Type Safety Patterns

### Use `typeof` for PrismaClient Parameters

Avoids slow TypeScript compilation:

```typescript
// ✅ Fast compilation
async function saveUser(db: typeof prisma) { ... }

// ❌ Slow compilation (causes type expansion)
async function saveUser(prisma: PrismaClient) { ... }
```

### Extract Types from Queries

```typescript
import { Prisma } from '@/generated/prisma/client'

const userWithPosts = Prisma.validator<Prisma.UserDefaultArgs>()({
  include: { posts: true },
})

type UserWithPosts = Prisma.UserGetPayload<typeof userWithPosts>
```

## Query Best Practices

### Select Only Needed Fields

```typescript
// ✅ Good - fetch only what you need
const users = await prisma.user.findMany({
  select: { id: true, email: true, name: true }
})

// ❌ Bad - fetches all fields
const users = await prisma.user.findMany()
```

### Avoid N+1 Queries

```typescript
// ✅ Good - single query with join
const posts = await prisma.post.findMany({
  include: { author: { select: { id: true, name: true } } }
})

// ❌ Bad - N+1 problem
const posts = await prisma.post.findMany()
for (const post of posts) {
  const author = await prisma.user.findUnique({ where: { id: post.authorId } })
}
```

## Schema Conventions

- **Models**: PascalCase (`User`, `Post`)
- **Fields**: camelCase (`firstName`, `createdAt`)
- **Relations**: plural for arrays (`posts`), singular for single (`profile`)
- **Always add indexes** on foreign keys and frequently queried fields

```prisma
model Post {
  id       Int  @id @default(autoincrement())
  authorId Int
  author   User @relation(fields: [authorId], references: [id])

  @@index([authorId])  // Index foreign keys
}
```

## Migrations

```bash
# Development: create and apply migration
npx prisma migrate dev --name add_feature

# Production: apply pending migrations
npx prisma migrate deploy

# Reset database (development only)
npx prisma migrate reset
```

## Transactions

```typescript
// Array transaction (independent operations)
await prisma.$transaction([
  prisma.user.create({ data: { ... } }),
  prisma.post.create({ data: { ... } }),
])

// Interactive transaction (dependent operations)
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { ... } })
  await tx.post.create({ data: { authorId: user.id, ... } })
})
```
