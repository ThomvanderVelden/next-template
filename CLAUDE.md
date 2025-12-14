# Next.js 16 Template

A modern Next.js template with authentication, database, and developer tooling.

## Tech Stack

- **Framework**: Next.js 16 with App Router
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS 4
- **Database**: PostgreSQL with Prisma 7
- **Authentication**: Better Auth
- **Linting/Formatting**: Biome

## Directory Structure

```
src/
├── app/           # Next.js App Router pages and layouts
│   └── api/       # API routes
├── lib/           # Shared utilities and configurations
│   ├── auth.ts    # Better Auth server instance
│   ├── auth-client.ts # Better Auth client
│   └── prisma.ts  # Prisma client singleton
└── generated/     # Generated code (Prisma client)

prisma/
├── schema.prisma  # Database schema
└── prisma.config.ts # Prisma configuration
```

## Commands

```bash
# Development
pnpm dev              # Start dev server with Turbopack
pnpm build            # Production build
pnpm lint             # Check for issues
pnpm lint:fix         # Auto-fix issues

# Database
pnpm db:generate      # Generate Prisma client
pnpm db:migrate       # Run migrations
pnpm db:push          # Push schema changes
pnpm db:studio        # Open Prisma Studio

# Docker
pnpm docker:up        # Start PostgreSQL
pnpm docker:down      # Stop PostgreSQL
```

## Code Standards

- Use tabs for indentation
- Use double quotes for strings
- TypeScript strict mode enabled
- Path alias: `@/*` maps to `./src/*`
- IMPORTANT: Run `pnpm lint:fix` after making changes
