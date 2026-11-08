# CI/CD Mac M4 Lab

Open **LAB_GUIDE.html** in your browser and follow the steps.

Includes a dependency-free Node.js web app, Node test suite, Dockerfile, Docker Compose five-container setup, GitHub Actions CI + GHCR publishing, and local canary/promotion/rollback scripts.

Run `./scripts/lab.sh init` from the kit root after Docker Desktop starts.

This educational lab uses three deterministic proxy endpoints (1 of 3 = 33%, not a true 10% traffic split). Deployment from GHCR to your Mac is deliberately manual.
