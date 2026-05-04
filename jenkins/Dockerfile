FROM jenkins/jenkins:2.452-lts-jdk17

USER root

# ── Dépendances système ──────────────────────────────────────
RUN apt-get update && apt-get install -y \
    docker.io \
    python3 python3-pip python3-venv \
    curl wget git unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Trivy (scan containers) ──────────────────────────────────
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin v0.51.0

# ── Cosign (signature images) ────────────────────────────────
RUN curl -sLO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 \
    && mv cosign-linux-amd64 /usr/local/bin/cosign \
    && chmod +x /usr/local/bin/cosign

# ── Gitleaks (secrets scan) ──────────────────────────────────
RUN curl -sLO https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_8.18.2_linux_x64.tar.gz \
    && tar -xzf gitleaks_*.tar.gz -C /usr/local/bin gitleaks \
    && rm gitleaks_*.tar.gz

# ── OWASP Dependency Check ───────────────────────────────────
RUN wget -q https://github.com/jeremylong/DependencyCheck/releases/download/v9.1.0/dependency-check-9.1.0-release.zip \
    && unzip -q dependency-check-*.zip -d /opt/ \
    && rm dependency-check-*.zip \
    && ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check

# ── Semgrep + Bandit (SAST Python) ───────────────────────────
RUN pip3 install --break-system-packages semgrep bandit

# ── Docker group pour accès socket ───────────────────────────
RUN groupadd -f docker && usermod -aG docker jenkins

USER jenkins

# ── Plugins Jenkins pré-installés ────────────────────────────
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
