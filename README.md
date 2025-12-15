# Next.js 16 Template

A production-ready Next.js template with authentication, database, and Azure deployment.

## Tech Stack

- **Framework**: Next.js 16 (App Router, Turbopack)
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS 4 + shadcn/ui
- **Database**: PostgreSQL with Prisma 7
- **Authentication**: Better Auth
- **Validation**: Zod (E2E type inference)
- **Linting**: Biome
- **Deployment**: Azure Container Apps

## Quick Start (Local Development)

```bash
# 1. Clone and install
git clone <your-repo-url> my-app
cd my-app
pnpm install

# 2. Set up environment
cp .env.example .env.local
# Edit .env.local with your values

# 3. Start PostgreSQL
pnpm docker:up

# 4. Set up database
pnpm db:generate
pnpm db:push

# 5. Run dev server
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to see your app.

## Environment Variables

Create `.env.local` with:

```bash
# Database (local Docker)
DATABASE_URL="postgresql://postgres:postgres@localhost:5433/next_template"

# Auth (generate with: openssl rand -base64 32)
BETTER_AUTH_SECRET="your-secret-here"
BETTER_AUTH_URL="http://localhost:3000"
```

## Commands

```bash
# Development
pnpm dev              # Start dev server
pnpm build            # Production build
pnpm lint             # Check for issues
pnpm lint:fix         # Auto-fix issues

# Database
pnpm db:generate      # Generate Prisma client
pnpm db:migrate       # Run migrations (production)
pnpm db:push          # Push schema changes (development)
pnpm db:studio        # Open Prisma Studio

# Docker
pnpm docker:up        # Start PostgreSQL
pnpm docker:down      # Stop PostgreSQL
pnpm docker:build     # Build app image
pnpm docker:run       # Run app container
```

---

## Deploying to Azure

This template deploys to Azure Container Apps with automated CI/CD via GitHub Actions.

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in
- [GitHub CLI](https://cli.github.com/) (optional)
- Azure subscription with Contributor access
- GitHub repository created from this template

### Step 1: Configure OIDC Authentication

Run the setup script to create Azure service principal and configure federated credentials:

```bash
# Edit these variables in the script first:
# - GITHUB_ORG: your GitHub username or organization
# - GITHUB_REPO: your repository name

./scripts/setup-oidc.sh
```

The script outputs three values you'll need for GitHub secrets.

### Step 2: Add GitHub Secrets

Go to your repo **Settings > Secrets and variables > Actions** and add:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | From setup script output |
| `AZURE_TENANT_ID` | From setup script output |
| `AZURE_SUBSCRIPTION_ID` | From setup script output |

### Step 3: Create GitHub Environments

Go to **Settings > Environments** and create environments for each stage you need:

- `dev` - Development
- `staging` - Staging (optional)
- `prod` - Production (optional)

For each environment, add these secrets:

| Secret | Description | How to generate |
|--------|-------------|-----------------|
| `POSTGRES_PASSWORD` | PostgreSQL admin password | `openssl rand -base64 24` |
| `BETTER_AUTH_SECRET` | Auth encryption secret | `openssl rand -base64 32` |
| `BETTER_AUTH_URL` | App URL | After first deploy, use the Container App URL |

### Step 4: Deploy Infrastructure

1. Go to **Actions** tab in your repo
2. Select **"Deploy Infrastructure"** workflow
3. Click **"Run workflow"**
4. Select environment (`dev`, `staging`, or `prod`)
5. Click **"Run workflow"**

This creates:
- Resource Group
- Container Registry
- Container Apps Environment
- Container App
- PostgreSQL Flexible Server
- Managed Identity
- Log Analytics + Application Insights

### Step 5: Deploy Application

The app deploys automatically on push to `main`. For manual deployment:

1. Go to **Actions** tab
2. Select **"Build and Deploy"** workflow
3. Click **"Run workflow"**
4. Select environment
5. Click **"Run workflow"**

### Step 6: Update BETTER_AUTH_URL

After first deployment, get your app URL from the workflow output or Azure Portal, then:

1. Go to **Settings > Environments > [your-env]**
2. Update `BETTER_AUTH_URL` secret with your Container App URL
   (e.g., `https://ca-myapp-dev-weu.westeurope.azurecontainerapps.io`)

### Post-Deployment

**View logs:**
```bash
az containerapp logs show \
  --name ca-myapp-dev-weu \
  --resource-group rg-myapp-dev-weu \
  --follow
```

**Run migrations manually (if needed):**
```bash
az containerapp exec \
  --name ca-myapp-dev-weu \
  --resource-group rg-myapp-dev-weu \
  --command "npx prisma migrate deploy"
```

**Open Prisma Studio (port-forward):**
```bash
# Get database connection string from Azure Portal
# Then run locally:
DATABASE_URL="your-azure-db-url" pnpm db:studio
```

---

## Project Structure

```
src/
├── app/              # Pages and API routes
├── components/       # React components
│   └── ui/           # shadcn/ui components
├── lib/              # Utilities and configs
│   ├── auth.ts       # Better Auth server
│   ├── auth-client.ts # Better Auth client
│   ├── prisma.ts     # Prisma client
│   ├── hooks/        # Custom React hooks
│   └── validations/  # Zod schemas
└── generated/        # Generated code (Prisma)

infrastructure/       # Azure Bicep templates
.github/workflows/    # CI/CD pipelines
```

## Documentation

For detailed development guidelines, see:
- `CLAUDE.md` - Project overview and deployment details
- `src/CLAUDE.md` - Frontend best practices and patterns
- `prisma/CLAUDE.md` - Database and Prisma 7 guide

## License

MIT
