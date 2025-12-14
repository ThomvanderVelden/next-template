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
- **Deployment**: Azure Functions (via OpenNext.js Azure)

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

infrastructure/
└── main.bicep        # Azure resource definitions (Bicep)

prisma.config.ts      # Prisma configuration (root)
open-next.config.ts   # OpenNext.js Azure adapter configuration
azure.config.json     # Azure deployment settings
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

# Azure Deployment
pnpm azure:build      # Build for Azure Functions
pnpm azure:deploy     # Deploy to Azure (provisions infra + deploys)
pnpm azure:logs       # Stream live logs from Azure
```

## Code Standards

- Use tabs for indentation
- Use double quotes for strings
- TypeScript strict mode enabled
- Path alias: `@/*` maps to `./src/*`
- IMPORTANT: Run `pnpm lint:fix` after making changes
- IMPORTANT: Update CLAUDE.md files after creating new features when necessary

## Azure Deployment

This template uses [OpenNext.js Azure](https://github.com/zpg6/opennextjs-azure) for serverless deployment to Azure Functions with full Next.js feature support.

### Prerequisites

1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
2. Logged in to Azure: `az login`
3. Active Azure subscription

### Configuration Files

- `azure.config.json` - Deployment settings (app name, region, environment)
- `open-next.config.ts` - Azure adapter configuration
- `infrastructure/main.bicep` - Azure resource definitions (auto-generated)

### Naming Convention

Resources follow the pattern: `{resourcetype}-{project}-{environment}-{region}`

| Resource Type       | Example Name                    |
|--------------------|---------------------------------|
| Resource Group     | `rg-myapp-prod-weu`             |
| Function App       | `func-myapp-prod-weu`           |
| Storage Account    | `stmyappprodweu`                |
| App Service Plan   | `asp-myapp-prod-weu`            |
| Application Insights | `appi-myapp-prod-weu`         |

**Region codes**: `weu` (West Europe), `neu` (North Europe), `swe` (Sweden Central), `eus` (East US), etc.

### First-time Setup

1. Edit `azure.config.json` with your app name and preferred region:
   ```json
   {
     "appName": "myapp",
     "resourceGroup": "rg-myapp-dev-weu",
     "location": "westeurope",
     "environment": "dev"
   }
   ```

2. Build and deploy:
   ```bash
   pnpm azure:build
   pnpm azure:deploy
   ```

### Environment Options

- `dev` - Consumption plan (Y1), pay-per-execution, auto-scale
- `test` - Consumption plan (Y1), for testing
- `staging` - Premium plan (EP1), always-ready, faster cold starts
- `prod` - Premium plan (EP1), GRS storage for redundancy

### Azure Resources Created

The deployment automatically provisions:
- **Storage Account** (`st{project}{env}{region}`): ISR cache, static assets, image optimization
- **Function App** (`func-{project}-{env}-{region}`): Serverless compute (Node.js 20)
- **App Service Plan** (`asp-{project}-{env}-{region}`): Y1 (dev) or EP1 (prod)
- **Application Insights** (`appi-{project}-{env}-{region}`): Monitoring and logging

### Database on Azure

For production, use Azure Database for PostgreSQL:
1. Create via Azure Portal or CLI
2. Update `DATABASE_URL` in Function App settings
3. Run migrations: `pnpm db:migrate`