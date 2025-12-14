# Next.js 16 Template

A modern Next.js template with authentication, database, and developer tooling.

## Tech Stack

- **Framework**: Next.js 16 with App Router
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS 4 + shadcn/ui
- **Database**: PostgreSQL with Prisma 7
- **Authentication**: Better Auth
- **Validation**: Zod (e2e type inference)
- **Linting/Formatting**: Biome

## Directory Structure

```
src/
├── app/              # Next.js App Router pages and layouts
│   ├── api/          # API routes
│   ├── sign-in/      # Sign in page
│   └── sign-up/      # Sign up page
├── components/       # React components
│   ├── ui/           # shadcn/ui components
│   └── header.tsx    # App header with auth
├── lib/              # Shared utilities and configurations
│   ├── auth.ts       # Better Auth server instance
│   ├── auth-client.ts # Better Auth client
│   ├── prisma.ts     # Prisma client singleton
│   ├── utils.ts      # Utility functions (cn, etc.)
│   └── validations/  # Zod schemas (source of truth for types)
│       ├── index.ts  # Re-exports all schemas
│       ├── auth.ts   # Auth-related schemas
│       └── common.ts # Reusable validation patterns
└── generated/        # Generated code (Prisma client)

prisma/
└── schema.prisma     # Database schema

prisma.config.ts      # Prisma configuration (root)
```

## E2E Typing Strategy

Types are defined once and used everywhere:

```
Prisma Schema → Prisma Types (database layer)
                     ↓
               Zod Schemas (validation + type inference)
                     ↓
               Shared Types (API + Frontend)
```

### Where to define types:

1. **Zod Schemas** (`lib/validations/`) - Primary source of truth
   - Input/output shapes for forms and APIs
   - Types are inferred with `z.infer<typeof schema>`
   - Same schema validates on client AND server

2. **Prisma Types** - For database queries
   - Import directly from `@/generated/prisma/client`
   - TypeScript infers types automatically from queries

### Usage examples:

```typescript
// Import validation schema + inferred type
import { signUpSchema, type SignUpInput } from "@/lib/validations"

// Use type for state
const [formData, setFormData] = useState<SignUpInput>({...})

// Validate with same schema on client AND server
const result = signUpSchema.safeParse(formData)
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
- IMPORTANT: Update CLAUDE.md files after creating new features when necessary