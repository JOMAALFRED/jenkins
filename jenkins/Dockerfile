FROM jenkins/jenkins:lts-jdk17

USER root

# ── Dépendances système ──────────────────────────────────────
RUN apt-get update && apt-get install -y \
    docker.io \
    python3 python3-pip python3-venv \
    curl wget git unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Gitleaks (secrets scan) ──────────────────────────────────
RUN curl -sLO https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz \
    && tar -xzf gitleaks_*.tar.gz -C /usr/local/bin gitleaks \
    && rm gitleaks_*.tar.gz

# ── Docker group pour accès socket ───────────────────────────
RUN groupadd -f docker && usermod -aG docker jenkins

USER jenkins

# ── Plugins Jenkins pré-installés ────────────────────────────
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
