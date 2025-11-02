# Framework GUI Development

Vue 3 + Tailwind CSS web interface for the Framework R package.

## Quick Start

### Development Mode (Recommended)

Run **two terminals**:

**Terminal 1** - Vite dev server (hot reload):
```bash
cd gui-dev
npm run dev
```
→ Access at **http://127.0.0.1:5173**

**Terminal 2** - R backend (API):
```bash
R -e "framework::gui()"
```
→ Runs on port 8080 (Vite proxies `/api/*` requests here)

### Production Mode

Test what end users will see:

```bash
cd gui-dev
npm run deploy   # Build + copy to inst/gui/
```

Then in R:
```r
devtools::load_all()
gui()  # Access at http://127.0.0.1:8080
```

## Deployment Workflow

After making UI changes:

1. **Test in dev mode** (port 5173)
2. **Build and deploy**: `npm run deploy`
3. **Test production build** (port 8080)
4. **Commit changes** including updated `inst/gui/` files

## Scripts

- `npm run dev` - Start Vite dev server (hot reload)
- `npm run build` - Build for production (outputs to `dist/`)
- `npm run deploy` - Build + copy to `inst/gui/`
- `npm run preview` - Preview production build locally

## File Structure

```
gui-dev/
├── src/
│   ├── components/
│   │   ├── ui/              # Reusable UI components
│   │   └── *.vue            # Feature components
│   ├── views/               # Page components (routes)
│   ├── composables/         # Vue composables
│   └── main.js              # App entry point
├── public/                  # Static assets (logo, etc.)
├── dist/                    # Build output (gitignored)
└── build-and-deploy.sh      # Deployment script

../inst/gui/                 # Production files (served by R)
```

## Design System

See `CLAUDE.md` for:
- Component library documentation
- Design patterns
- Coding standards
- Color scheme (sky accent)

## Notes

- **Production**: R package serves from `inst/gui/` (no Node.js required)
- **Development**: Vite proxies API calls to R backend on port 8080
- **Logo**: `public/framework-logo.png` is copied to build automatically
