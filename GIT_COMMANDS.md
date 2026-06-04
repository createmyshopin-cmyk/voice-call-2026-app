# Git Initialization Commands

Copy-paste these commands in sequence to initialize and push each repository to GitHub.

---

## Repository 1: backend-api (NestJS)

```bash
# Navigate to the backend-api repository directory
cd backend-api

# Initialize a new git repository
git init

# Stage all files (respects .gitignore — will exclude node_modules, dist, .env)
git add .

# Create initial commit
git commit -m "Initial backend release — NestJS + Supabase + Razorpay + Agora"

# Link to your GitHub remote (replace with your actual repo URL)
git remote add origin https://github.com/createmyshopin-cmyk/backend-api.git

# Push to main branch
git branch -M main
git push -u origin main
```

---

## Repository 2: admin-panel (Next.js)

```bash
# Navigate to the admin-panel repository directory
cd admin-panel

# Initialize a new git repository
git init

# Stage all files (respects .gitignore — will exclude node_modules, .next, .env.local)
git add .

# Create initial commit
git commit -m "Initial admin panel release — Next.js admin dashboard"

# Link to your GitHub remote (replace with your actual repo URL)
git remote add origin https://github.com/createmyshopin-cmyk/admin-panel.git

# Push to main branch
git branch -M main
git push -u origin main
```

---

## Repository 3: flutter-app (Flutter)

```bash
# Navigate to the flutter-app repository directory
cd flutter-app

# Initialize a new git repository
git init

# Stage all files (respects .gitignore — will exclude build/, .dart_tool/, google-services.json)
git add .

# Create initial commit
git commit -m "Initial flutter app release — Coin-based voice calling Android app"

# Link to your GitHub remote (replace with your actual repo URL)
git remote add origin https://github.com/createmyshopin-cmyk/flutter-app.git

# Push to main branch
git branch -M main
git push -u origin main
```

---

## Post-Setup: Configure Deployment Services

After pushing to GitHub:

1. **Railway** (for backend-api): Import `backend-api` repo → add environment variables → deploy
2. **Vercel** (for admin-panel): Import `admin-panel` repo → set `NEXT_PUBLIC_API_URL` → deploy
3. **Flutter**: Ensure `google-services.json` is in `android/app/` locally, then run `flutter build appbundle --release` and upload to Google Play Console
