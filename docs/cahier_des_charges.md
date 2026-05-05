# Cahier des charges

## Intitule

Projet CI/CD securise avec Jenkins, Docker et Harbor.

## Objectif

Mettre en place une chaine CI/CD DevSecOps capable de construire, tester,
analyser, signer, scanner et deployer une image Docker de maniere controlee.
Jenkins orchestre le pipeline, Docker produit les images, Trivy et les outils
SAST verifient la securite, Cosign assure la signature et Harbor represente le
registre prive cible.

## Perimetre fonctionnel

- Application FastAPI exposee sur le port `8000`.
- Tests unitaires automatises.
- Pipeline Jenkins declaratif.
- Construction d'une image Docker applicative.
- Scan de code source avec Bandit et Semgrep.
- Detection de secrets avec Gitleaks.
- Scan d'image avec Trivy.
- Signature et verification d'image avec Cosign.
- Push vers un registre local ou Harbor.
- Deploiement via Docker Compose.

## Exigences de securite

- Aucun secret en clair dans le depot.
- Secrets injectes par Jenkins credentials ou variables d'environnement.
- Image refusee si des vulnerabilites critiques ou hautes sont detectees.
- Image signee avant promotion vers l'environnement cible.
- Verification de signature avant deploiement.
- Documentation des risques et controles associes.

## Livrables

- Code source FastAPI.
- `Jenkinsfile`.
- `Dockerfile` et `docker-compose.yml`.
- Scripts de scan, signature et verification.
- Documentation projet.
- Analyse de risques STRIDE.
- Rapport final et demonstration.

## Critere de reussite

Le projet est valide si le pipeline peut executer automatiquement les tests, les
controles de securite, la construction d'image, le scan, la signature et le push
vers un registre sans intervention manuelle hors configuration initiale.
