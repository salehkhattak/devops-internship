# Week 7 — Continuous Integration (CI)

This week focuses on implementing a Continuous Integration (CI) pipeline for the Parallax microservice using GitHub Actions.

The pipeline automatically runs linting and unit tests on code changes, then builds and publishes a Docker image to GitHub Container Registry (GHCR) when changes are pushed to the `main` branch.

## Objectives

- Set up GitHub Actions for continuous integration.
- Run linting on every push.
- Run unit tests on every push.
- Build a Docker image after successful tests.
- Push the Docker image to GitHub Container Registry.
- Tag Docker images using the Git commit SHA.
- Publish images only from the `main` branch.
- Verify the complete CI pipeline through GitHub Actions.

## Project Structure

```text
weak 7/
├── app/
│   ├── tests/
│   │   └── unit.test.js
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── app.js
│   ├── package.json
│   └── package-lock.json
│
└── README.md

.github/
└── workflows/
    └── ci.yml
```

## Technology Stack

- Node.js 20
- npm
- GitHub Actions
- Docker
- GitHub Container Registry (GHCR)
- Git

## CI Pipeline

```text
             Git Push / Pull Request
                      │
                      ▼
              ┌───────────────┐
              │ Checkout Code │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Setup Node.js  │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ npm ci         │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Run Lint       │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Run Unit Tests │
              └───────┬───────┘
                      │
                 Tests Pass
                      │
                      ▼
              ┌───────────────┐
              │ Docker Build   │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Push to GHCR   │
              └───────────────┘
```

### Linting

The project runs linting using:

```text
npm run lint
```

This command executes `node --check app.js`, which verifies the JavaScript code for syntax errors without executing it.

### Unit Testing

Unit tests are run using:

```text
npm test
```

The tests validate important application behavior including:

- Istio metadata detection
- mTLS detection
- Trace ID fallback
- User-agent defaults
- Environment variable defaults
- Docker image tag validation

**Example result:**

```text
Results: 8 passed, 0 failed

All tests passed!
```

### Docker

The application is containerized using the project's Dockerfile.

Build the image locally:

```bash
docker build -t parallax-microservice ./app
```

Run the container:

```bash
docker run -p 3000:3000 parallax-microservice
```

The application should then be available at:

```
http://localhost:3000
```

### GitHub Container Registry

The CI pipeline publishes Docker images to GitHub Container Registry:

```
ghcr.io
```

The image follows this naming convention:

```
ghcr.io/<github-username>/parallax-microservice:<git-commit-sha>
```

**For example:**

```
ghcr.io/example-user/parallax-microservice:a8f31c9
```

### Image Tagging Strategy

Docker images are tagged using the Git commit SHA.

The workflow uses:

```
ghcr.io/${{ github.repository_owner }}/parallax-microservice:${{ github.sha }}
```

This creates a unique and traceable Docker image for every commit.

**For example:**

```
Git Commit:
a8f31c9...

Docker Image:
ghcr.io/example-user/parallax-microservice:a8f31c9...
```

### GitHub Actions Workflow

The CI workflow is located at:

```
.github/workflows/ci.yml
```

#### On Every Push

The workflow performs:

- Checkout
- Setup Node.js
- Install dependencies
- Lint
- Unit Tests

#### On Main Branch

When changes are pushed to `main` and linting and tests pass:

- Lint & Tests
- Docker Build
- Login to GHCR
- Push Docker Image

Pull requests targeting `main` run the lint and test stage but do not publish a Docker image.

### GitHub Actions Permissions

The Docker publishing job requires permission to write packages:

```yaml
permissions:
  contents: read
  packages: write
```

GitHub's automatically provided `GITHUB_TOKEN` is used to authenticate with GHCR.

No personal Docker Hub credentials are required.

### Verification

After pushing changes to GitHub:

1. Open the repository on GitHub.
2. Go to the **Actions** tab.
3. Open the latest CI workflow.
4. Verify that linting passes.
5. Verify that unit tests pass.
6. Verify that the Docker image builds successfully.
7. Verify that the Docker image is pushed to GHCR.
8. Open the repository's **Packages** section.
9. Verify that the `parallax-microservice` image exists.
10. Verify that the image is tagged with the Git commit SHA.

#### Pull the Published Image

After the image has been published, it can be pulled using:

```bash
docker pull ghcr.io/<github-username>/parallax-microservice:<git-commit-sha>
```

**Example:**

```bash
docker pull ghcr.io/example-user/parallax-microservice:a8f31c9
```

## What I Learned

Through this task, I learned how to:

- Create a GitHub Actions CI workflow.
- Automate linting and unit testing.
- Use `npm ci` for reproducible dependency installation.
- Build Docker images inside GitHub Actions.
- Authenticate GitHub Actions with GHCR.
- Publish Docker images automatically.
- Use Git commit SHA for Docker image versioning.
- Implement branch‑based CI behavior.
- Connect source‑code changes with reproducible container images.

## Future Improvements

Possible improvements to the CI pipeline include:

- Add Trivy security scanning.
- Add Docker image vulnerability scanning.
- Add code coverage reporting.
- Add Docker image caching.
- Add semantic version tags.
- Add automated deployment to Kubernetes.
- Implement Continuous Deployment (CD) using Argo CD.
- Add Prometheus and Grafana monitoring.

## Week 7 Result

The project now has an automated CI pipeline that:

- ✅ Runs linting
- ✅ Runs unit tests
- ✅ Builds Docker images
- ✅ Tags images with Git commit SHA
- ✅ Publishes images to GHCR
- ✅ Runs automatically through GitHub Actions

---

**Week 7 — Continuous Integration completed.**