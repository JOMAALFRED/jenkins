# Projet CI/CD securise avec Jenkins, Docker et Harbor

## Sujet

Securisation de la Supply Chain Logicielle : mise en place d'un pipeline CI/CD
securise avec Jenkins, Docker et Harbor.

## Objectif global

Concevoir, implementer et demontrer une chaine CI/CD securisee assurant la
construction, la verification, la signature, le scan et le deploiement controle
d'images Docker via Jenkins et un registre prive. Le projet s'inscrit dans une
demarche DevSecOps et vise a garantir la confiance, la tracabilite et
l'integrite du code et des artefacts tout au long du cycle de vie logiciel.

## Contexte

Les attaques sur la supply chain logicielle, comme SolarWinds, Log4j ou le
poisoning d'images publiques, montrent la necessite de securiser les pipelines
CI/CD. Dans cette variante du sujet, Jenkins orchestre les controles de
securite, Docker construit les artefacts, Trivy analyse les images, Cosign
assure la signature et Harbor represente la cible de registre prive avec des
politiques de securite. Pour les tests locaux, le projet fournit aussi un
registre Docker compatible sur `localhost:8090`.

## Objectifs techniques

- Creer un pipeline Jenkins automatise incluant tests, SAST, scan de secrets,
  build Docker, scan d'image, signature et push vers un registre.
- Mettre en place une application FastAPI conteneurisee servant de support de
  demonstration.
- Centraliser les scripts de securite reutilisables pour Trivy et Cosign.
- Preparer l'integration Harbor : registre prive, scan de vulnerabilites,
  controle d'acces, politiques de retention et blocage des images non
  conformes.
- Realiser une analyse de risques du pipeline avec STRIDE et documenter les
  controles OWASP pertinents.

## Architecture cible

```text
Developpeur -> Depot Git
                 |
                 v
              Jenkins
                 |
                 |-- Stage 1 : Tests unitaires
                 |-- Stage 2 : Static Analysis (Bandit, Semgrep, Gitleaks)
                 |-- Stage 3 : Build Docker image
                 |-- Stage 4 : Container Scanning (Trivy)
                 |-- Stage 5 : Signature de l'image (Cosign)
                 |-- Stage 6 : Push vers Harbor ou registre local
                 |-- Stage 7 : Verification et deploiement Docker Compose
                 |
                 v
        Harbor / Registre prive -> Serveur Docker Compose
```

## Stack technique

- Jenkins : orchestration CI/CD.
- Docker et Docker Compose : conteneurisation et deploiement.
- Harbor : registre prive cible, scan et politiques de securite.
- Registry Docker local : registre de demonstration sur `localhost:8090`.
- Trivy : scan de vulnerabilites d'images.
- Cosign : signature et verification d'images.
- Bandit et Semgrep : SAST Python.
- Gitleaks : detection de secrets.
- Python 3.12 et FastAPI : application de demonstration.
- Pytest et HTTPX : tests automatises.

## Structure

```text
.
├── Jenkinsfile
├── Dockerfile
├── docker-compose.yml
├── docker-compose.deploy.yml
├── README.md
├── docs/
│   ├── cahier_des_charges.md
│   └── analyse_risques.md
├── jenkins/
│   ├── Dockerfile
│   └── plugins.txt
├── scripts/
│   ├── scan.sh
│   ├── sign.sh
│   └── verify.sh
├── src/
│   ├── app.py
│   └── utils.py
└── tests_stable/
    └── test_api.py
```

Les dossiers `scr/`, `scrpits/`, `secure-cicd/` et `tests/` sont ignores : ils
correspondent a des brouillons ou fichiers herites. Les archives Harbor lourdes
restent locales et ne sont pas suivies par Git.

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

Avec Podman socket :

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
2. installation des dependances Python ;
3. tests unitaires avec rapport JUnit ;
4. SAST avec Bandit, Semgrep et Gitleaks ;
5. build de l'image Docker ;
6. scan Trivy ;
7. push vers le registre configure ;
8. generation ou reutilisation des cles Cosign ;
9. signature de l'image par digest ;
10. verification de signature ;
11. deploiement controle via Docker Compose ;
12. verification de sante de l'application deployee.

Le pipeline refuse l'image si Trivy detecte une vulnerabilite `HIGH` ou
`CRITICAL`. La signature et la verification Cosign utilisent le digest retourne
par `docker push`, afin de garantir que l'artefact signe correspond exactement a
l'image publiee dans le registre.

## Demonstration finale

Avant la demonstration, demarrer la stack :

```bash
docker compose up -d --build
```

Avec Podman rootless :

```bash
cp .env.example .env
sed -i "s|DOCKER_SOCKET=.*|DOCKER_SOCKET=/run/user/$(id -u)/podman/podman.sock|" .env
docker compose up -d --build
```

Variables locales attendues dans `.env` :

```env
DOCKER_SOCKET=/run/user/1000/podman/podman.sock
COSIGN_PASSWORD=change-me
COSIGN_REGISTRY_ALIAS=host.containers.internal:8090
```

Lancer le job Jenkins `DevSecOps-pipeline`, puis verifier les stages :

```text
Checkout
Python tests
SAST
Build image
Trivy scan
Push image
Prepare signing keys
Sign image
Verify signature
Deploy
```

Resultat attendu :

```text
Finished: SUCCESS
```

Application deployee par le pipeline :

```bash
curl http://localhost:8001/health
```

Si le port n'est pas accessible directement depuis l'hote, verifier dans le
conteneur :

```bash
docker exec devsecops-api-deployed python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5).read().decode())"
```

## Preuves a inclure dans le rapport

- Capture du job Jenkins termine en `SUCCESS`.
- Capture des stages `Trivy scan`, `Sign image`, `Verify signature` et
  `Deploy`.
- Extrait du rapport JUnit montrant les tests Python.
- Extrait Trivy avec `Aucune vulnerabilite CRITICAL,HIGH detectee`.
- Extrait Cosign indiquant que la signature est valide.
- Reponse du endpoint `/health` de l'application deployee.

## Couverture du sujet

Elements implementes :

- CI/CD Jenkins declaratif.
- Tests automatises.
- SAST avec Bandit et Semgrep.
- Detection de secrets avec Gitleaks.
- Build Docker.
- Scan d'image avec Trivy.
- Blocage des images vulnerables.
- Push vers registre local compatible Docker Registry.
- Signature Cosign de l'image par digest.
- Verification de signature avant deploiement.
- Deploiement controle via Docker Compose.
- Analyse de risques STRIDE.

Harbor est prepare dans le depot et reste l'extension naturelle du registre
local pour une mise en production : RBAC, policies, retention, scan integre et
controle d'acces avance.

## Plan de travail

- Phase 1 : conception, analyse des menaces et setup Jenkins/Docker/registre.
- Phase 2 : integration CI/CD avec tests, SAST, build, scan et push.
- Phase 3 : securisation avec signature, verification, secrets et politiques.
- Phase 4 : audit, documentation, rapport final et demonstration technique.

## Axes d'approfondissement

- Remplacer le registre local par Harbor complet avec RBAC et policies.
- Ajouter OWASP Dependency Check pour le scan des dependances.
- Generer un SBOM avec Syft et le verifier dans le pipeline.
- Ajouter une etape Policy-as-Code avec OPA ou Conftest.
- Ajouter Prometheus et Grafana pour le monitoring securite.
