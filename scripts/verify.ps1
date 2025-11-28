Write-Host "🚀 Starting ECONEURA-GO Verification..." -ForegroundColor Cyan

# 1. Linting
Write-Host "`n🔍 Running Lint..." -ForegroundColor Yellow
npm run lint
if ($LASTEXITCODE -ne 0) { Write-Error "Lint failed!"; exit 1 }

# 2. Type Checking
Write-Host "`n📝 Running Type Check..." -ForegroundColor Yellow
npm run type-check
if ($LASTEXITCODE -ne 0) { Write-Error "Type check failed!"; exit 1 }

# 3. Tests
Write-Host "`n🧪 Running Tests..." -ForegroundColor Yellow
npm test --workspaces
if ($LASTEXITCODE -ne 0) { Write-Error "Tests failed!"; exit 1 }

# 4. Build
Write-Host "`n🏗️ Running Build..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) { Write-Error "Build failed!"; exit 1 }

Write-Host "`n✅ VERIFICATION COMPLETE: ALL SYSTEMS GO!" -ForegroundColor Green
