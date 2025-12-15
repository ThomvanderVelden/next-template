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
- **Deployment**: Azure Container Apps (Docker + GitHub Actions)

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
├── main.bicep        # Main Bicep orchestrator
└── modules/          # Bicep modules (acr, identity, container-app, monitoring)

.github/workflows/
├── deploy.yml        # CI/CD: Build and deploy to Container Apps
└── infrastructure.yml # Deploy Azure infrastructure

Dockerfile            # Multi-stage Docker build for Next.js
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

# Docker (local PostgreSQL)
pnpm docker:up        # Start PostgreSQL
pnpm docker:down      # Stop PostgreSQL

# Docker (app container)
pnpm docker:build     # Build Docker image
pnpm docker:run       # Run Docker container locally
```

## Code Standards

- Use tabs for indentation
- Use double quotes for strings
- TypeScript strict mode enabled
- Path alias: `@/*` maps to `./src/*`
- IMPORTANT: Run `pnpm lint:fix` after making changes
- IMPORTANT: Update CLAUDE.md files after creating new features when necessary

## Azure Deployment

This template uses Azure Container Apps with GitHub Actions for automated CI/CD deployment.

### Prerequisites

1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
2. [GitHub CLI](https://cli.github.com/) (optional, for managing secrets)
3. Azure subscription with Contributor access

### Naming Convention

Resources follow the pattern: `{resourcetype}-{project}-{environment}-{region}`

| Resource Type        | Example Name                    |
|---------------------|--------------------------------|
| Resource Group      | `rg-myapp-dev-weu`             |
| Container Registry  | `acrmyappdevweu`               |
| Container App       | `ca-myapp-dev-weu`             |
| Container Apps Env  | `cae-myapp-dev-weu`            |
| Managed Identity    | `id-myapp-dev-weu`             |
| PostgreSQL Server   | `psql-myapp-dev-weu`           |
| App Insights        | `appi-myapp-dev-weu`           |

**Region codes**: `weu` (West Europe), `neu` (North Europe), `swe` (Sweden Central), `eus` (East US), etc.

### First-time Setup

1. **Configure OIDC authentication** (one-time):
   ```bash
   # Update GITHUB_ORG and GITHUB_REPO in the script first
   ./scripts/setup-oidc.sh
   ```

2. **Add GitHub secrets** (from script output):
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

3. **Create GitHub environments** (dev, staging, prod) with secrets:
   - `POSTGRES_PASSWORD` - PostgreSQL admin password (`openssl rand -base64 24`)
   - `BETTER_AUTH_SECRET` - Auth secret (`openssl rand -base64 32`)
   - `BETTER_AUTH_URL` - App URL (e.g., `https://ca-myapp-dev-weu.westeurope.azurecontainerapps.io`)

4. **Deploy infrastructure** (GitHub Actions):
   - Run "Deploy Infrastructure" workflow
   - Select environment (dev/staging/prod)

5. **Deploy app** (automatic on push to main, or manual):
   - Run "Build and Deploy" workflow

### Environment Scaling

| Environment | Min Replicas | Max Replicas | Notes |
|------------|-------------|-------------|-------|
| dev        | 0           | 3           | Scale to zero (cost efficient) |
| staging    | 0           | 5           | Scale to zero |
| prod       | 1           | 10          | Always-on (no cold starts) |

### Azure Resources Created

The deployment automatically provisions:
- **Container Registry** (`acr{project}{env}{region}`): Docker image storage
- **Container App** (`ca-{project}-{env}-{region}`): Serverless container hosting
- **PostgreSQL Flexible Server** (`psql-{project}-{env}-{region}`): Managed PostgreSQL database
- **Managed Identity** (`id-{project}-{env}-{region}`): ACR pull authentication
- **Log Analytics** (`log-{project}-{env}-{region}`): Centralized logging
- **Application Insights** (`appi-{project}-{env}-{region}`): Monitoring and tracing

### PostgreSQL Sizing

| Environment | SKU | Storage | High Availability |
|------------|-----|---------|-------------------|
| dev        | B1ms (Burstable) | 32 GB | Disabled |
| staging    | B2s (Burstable) | 64 GB | Disabled |
| prod       | D2s_v3 (General Purpose) | 128 GB | Zone Redundant |

### Local Docker Testing

```bash
# Build the image
pnpm docker:build

# Run locally (requires .env.local with DATABASE_URL, etc.)
pnpm docker:run
```

### Database Connection

PostgreSQL is automatically provisioned and connected. The `DATABASE_URL` is generated and injected into the Container App at deployment time.

**Connection details:**
- User: `pgadmin`
- Database: `app`
- SSL: Required

To run migrations after deployment:
```bash
# Connect to the container and run migrations
az containerapp exec \
  --name ca-myapp-dev-weu \
  --resource-group rg-myapp-dev-weu \
  --command "npx prisma migrate deploy"
```