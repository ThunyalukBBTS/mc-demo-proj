# Larvae Survey Project (ระบบการเฝ้าระวังลูกน้ำยุงลาย)

This repository contains the full stack code for the Larvae Survey application, including the Supabase database migrations/seeding configs and the Vue.js + Vite frontend application.

---

## Project Structure

```
├── .env                              # Root environment variables for Supabase database & keys
├── frontends/
│   └── vhv-larvae-survey/            # Vue.js + Vite client SPA
│       ├── .env.local                # Local environment client keys
│       ├── .env.prod                 # Production environment client keys
│       ├── package.json              # Frontend scripts and dependencies
│       └── wrangler.toml             # Cloudflare Pages deployment configuration
├── supabase/
│   ├── config.toml                   # Supabase local config (ports, auth, etc.)
│   ├── migrations/                   # SQL migration scripts (table schemas, triggers)
│   └── seeding/
│       └── seed.sql                  # Seeding data (Villages list)
└── scripts/
    └── generate-village-seed/        # Utility script to parse DOPA JSON and generate seed SQL
```

---

## Setup & Run Instructions

### 1. Configure Environment Variables
You must edit/create the environment files before running the project.

#### A. Root Environment (`/.env`)
Create or edit `.env` in the project root:
```ini
SUPABASE_URL=your_supabase_url
SUPABASE_PUBLISHABLE_KEY=your_publishable_key
```

#### B. Frontend Environment (`/frontends/vhv-larvae-survey/.env.local` or `.env.prod`)
Create or edit `.env.local` (for development) and `.env.prod` (for production builds):
```ini
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_PUBLISHABLE_KEY=your_publishable_key
```

---

### 2. Database Setup (Supabase)
To start and provision your local Supabase database instance:

```bash
# Start local Supabase services
supabase start

# Reset the database, which automatically runs migrations and loads seeding data from /supabase/seeding/seed.sql
supabase db reset
```

#### (Optional) Re-generating Village Seeds
If you need to update the village lists from DOPA:
1. Download address JSON from DOPA into `/scripts/generate-village-seed/khonkaen.json`.
2. Run the generator:
   ```bash
   cd scripts/generate-village-seed
   python3 generate_seed.py
   ```
3. Reset your database (`supabase db reset`) to load the new generated `seed.sql`.

---

### 3. Running the Frontend (Vue.js Client)
Navigate to the frontend directory:
```bash
cd frontends/vhv-larvae-survey
```

#### A. Install Dependencies
```bash
bun install
# or npm install / yarn install
```

#### B. Run Local Development Server
Starts the dev server at http://localhost:5180/:
```bash
bun run dev
# or npm run dev
```

#### C. Build Commands
We have separated the build commands to target specific environment files:
```bash
# Build using local variables (.env.local)
bun run build:local

# Build using dev variables (.env.dev)
bun run build:dev

# Build using production variables (.env.prod)
bun run build:prod
# (or the standard alias)
bun run build
```

---

### 4. Deploying to Cloudflare Pages
To deploy the compiled static assets to Cloudflare Pages free tier:

1. Ensure you have built the application (`bun run build`).
2. Login to Cloudflare:
   ```bash
   wrangler login
   ```
3. Deploy using the configured `wrangler.toml`:
   ```bash
   bun run deploy
   # or npx wrangler pages deploy
   ```

---

## Generative AI Project Prompts (`/prompts`)
This folder contains the core Generative AI prompt specifications that define the layout, behavior, database schema, and design patterns for this project. When utilizing AI coding assistants, these files serve as the ground-truth base instructions:

*   **[SYS_ARCH.md](file:///home/btxs/Desktop/workstation/mc-demo-proj/prompts/SYS_ARCH.md)**: Outlines the system architecture and tech stack requirements (Vue.js, Bun, Tailwind, Supabase, and Cloudflare).
*   **[DB.md](file:///home/btxs/Desktop/workstation/mc-demo-proj/prompts/DB.md)**: Details the database schema design, including villages (filtered for Mancha Khiri district), VHVs, junctions, and survey records, as well as generate-on-demand HI and CI index logic.
*   **[WEB.md](file:///home/btxs/Desktop/workstation/mc-demo-proj/prompts/WEB.md)**: Defines the user experience, page specifications (Dashboard charts/tables, Daily Larvae Survey input form with autocomplete, and Legacy data tables), and target personas/use-cases.
