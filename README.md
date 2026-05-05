# Jenkins DevSecOps Project

Projet de demonstration DevSecOps avec FastAPI, Jenkins, Gitea, un registre
Docker local, Trivy, Bandit, Semgrep, Gitleaks et Cosign.

## Structure

- `src/` : application FastAPI.
- `tests_stable/` : tests automatises maintenables.
- `scripts/` : scripts de scan Trivy, signature Cosign et verification.
- `jenkins/` : image Jenkins avec les outils CI/CD et securite.
- `harbor/` : anciens artefacts d'installation Harbor conserves localement si
  necessaire, mais non suivis par Git.

Les dossiers `scr/`, `scrpits/`, `secure-cicd/` et `tests/` sont conserves
localement mais ignores : ils correspondent a des brouillons ou fichiers herites
non maintenables dans l'etat actuel.

## Tests locaux

```bash
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m pytest --junitxml=reports/junit.xml
```

## Lancement local

```bash
docker compose up --build
```

Avec Podman socket, lancer par exemple :

```bash
DOCKER_SOCKET=/run/user/$(id -u)/podman/podman.sock docker compose up --build
```

Services exposes :

- API FastAPI : `http://localhost:8000`
- Jenkins : `http://localhost:8080`
- Gitea : `http://localhost:3000`
- Trivy cache server : `http://localhost:4954`
- Registre local compatible Docker Registry : `localhost:8090`

## Pipeline Jenkins

Le `Jenkinsfile` execute :

1. checkout du depot ;
2. installation Python ;
3. tests unitaires avec rapport JUnit ;
4. SAST avec Bandit, Semgrep et Gitleaks ;
5. build de l'image Docker ;
6. scan Trivy ;
7. push vers le registre local configure.
