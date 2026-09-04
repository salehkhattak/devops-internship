# Week 7 – Continuous Integration (CI)

> **Internship Programme – Parallax Labs**  
> Week: Aug 29 – Sep 4  
> Author: Saleh Khattak

---

## 📋 Overview

This week implements a full **Continuous Integration (CI)** pipeline using **GitHub Actions** for the Parallax microservices repository. The pipeline automates linting, unit testing, Docker image building, and image publishing to **GitHub Container Registry (GHCR)** on every push to `main`.

---

## 🗂️ Directory Structure

```
weak 7/
├── app/
│   ├── app.js               # (copied from Week 5 – microservice source)
│   ├── Dockerfile           # Production-ready Dockerfile (node:20-alpine)
│   ├── .dockerignore        # Keeps image lean
│   ├── package.json         # Added lint + test scripts
│   └── tests/
│       └── unit.test.js     # Unit tests (run by CI)
└── README.md                # This file

.github/
└── workflows/
    └── ci.yml               # GitHub Actions CI workflow
```

---

## ⚙️ GitHub Actions Workflow

**File:** [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

### Trigger Conditions

| Event         | Branches      | Jobs triggered             |
|---------------|---------------|----------------------------|
| `push`        | All branches  | Lint & Test, CI Summary    |
| `push`        | `main` only   | + Build & Push Docker image|
| `pull_request`| `main`        | Lint & Test, CI Summary    |

### Jobs

#### 🔍 Job 1 – `lint-and-test`
Runs on **every push** and **every PR** to `main`.

| Step | Command |
|------|---------|
| Install deps | `npm ci` |
| Lint (syntax check) | `npm run lint` → `node --check app.js` |
| Unit tests | `npm test` → `node tests/unit.test.js` |

#### 🐳 Job 2 – `build-and-push`
Runs **only on `main` branch merges** after `lint-and-test` succeeds.

| Step | Detail |
|------|--------|
| Image registry | GitHub Container Registry (`ghcr.io`) |
| Authentication | `GITHUB_TOKEN` (auto-provided, no manual secret needed) |
| Platforms | `linux/amd64`, `linux/arm64` (multi-arch) |
| Build cache | GitHub Actions cache (`type=gha`) |

#### 📋 Job 3 – `ci-summary`
Always runs and posts a markdown summary to the Actions run page.

---

## 🏷️ Image Tagging Strategy

| Tag | Example | When applied |
|-----|---------|--------------|
| Git commit SHA | `sha-a1b2c3d` | Every `main` push |
| Semantic version | `v1.2.3` | When a Git tag like `v*` is pushed |
| `latest` | `latest` | Every `main` push |

**Full image name pattern:**
```
ghcr.io/<github-username>/parallax-microservice:<tag>
```

---

## 🧪 Unit Tests

Test file: [`app/tests/unit.test.js`](app/tests/unit.test.js)

| Test | What it checks |
|------|---------------|
| mTLS detection | `x-forwarded-client-cert` header → `mtlsActive: true` |
| No mTLS | Missing XFCC header → `mtlsActive: false` |
| TraceID fallback | Falls back to `x-request-id` when `x-b3-traceid` absent |
| UserAgent default | Defaults to `"Unknown"` when header missing |
| PORT default | Defaults to `3000` |
| SERVICE_NAME default | Defaults to `"frontend"` |
| APP_ENV default | Defaults to `"development"` |
| Image tag format | SHA tag is ≥7 characters |

Run locally:
```bash
cd "weak 7/app"
npm ci
npm run lint
npm test
```

---

## 🚀 Setup Instructions

### 1. Prerequisites
- Push this repository to GitHub
- Ensure your GitHub account has **Packages** enabled

### 2. Enable GHCR (No extra secrets needed!)
The workflow uses `GITHUB_TOKEN` which is **automatically available** in all GitHub Actions runs. No manual secrets required for GHCR.

### 3. Trigger the pipeline
```bash
git add .
git commit -m "ci: add GitHub Actions CI pipeline (Week 7)"
git push origin main
```

### 4. Verify in GitHub
1. Go to your repo → **Actions** tab
2. Watch the `CI – Lint, Test & Build Docker Image` workflow run
3. After success on `main`, go to **Packages** tab to see the pushed image

### 5. Pull and run the image locally
```bash
# Pull the image (replace <SHA> with the actual commit SHA)
docker pull ghcr.io/<your-github-username>/parallax-microservice:sha-<SHA>

# Run it
docker run -p 3000:3000 ghcr.io/<your-github-username>/parallax-microservice:sha-<SHA>

# Test it
curl http://localhost:3000/health
```

---

## ✅ Deliverable Checklist

| Requirement | Status |
|-------------|--------|
| GitHub Actions workflow set up | ✅ `.github/workflows/ci.yml` |
| Linting on every push | ✅ `npm run lint` (`node --check`) |
| Unit tests on every push | ✅ `npm test` (8 test cases) |
| Docker image build on `main` merge | ✅ `docker/build-push-action@v5` |
| Push to container registry | ✅ GHCR (`ghcr.io`) |
| Image tagging with Git commit SHA | ✅ `sha-<shortSHA>` tag |
| Semantic version tagging | ✅ `type=semver` tag |
| `latest` tag on `main` | ✅ `type=raw,value=latest` |

---

## 🔗 Related Weeks

| Week | Topic |
|------|-------|
| [Week 5](../weak%205/) | Istio Service Mesh + Helm |
| [Week 6](../weak%206/) | Kong API Gateway + Rate Limiting + API Key Auth |
| **Week 7** | **CI Pipeline (this week)** |
