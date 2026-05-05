# Analyse de risques STRIDE

## Contexte

Le pipeline CI/CD manipule du code source, des secrets, des images Docker et des
artefacts signes. Les principaux actifs a proteger sont le depot Git, Jenkins,
les credentials, le registre d'images, les images produites et le serveur de
deploiement.

## Spoofing

Risque : un acteur non autorise se fait passer pour un developpeur, Jenkins ou
le registre.

Controles :

- Authentification Jenkins.
- Credentials Jenkins pour les secrets.
- Registre prive avec authentification.
- Verification de signature Cosign avant deploiement.

## Tampering

Risque : modification non autorisee du code, du pipeline ou des images Docker.

Controles :

- Historique Git et revue des changements.
- Pipeline declaratif versionne.
- Signature des images.
- Verification de digest avant deploiement.
- Scan de l'image avant push ou promotion.

## Repudiation

Risque : impossibilite de prouver qui a declenche ou modifie une action.

Controles :

- Logs Jenkins.
- Historique Git.
- Rapports JUnit et rapports de scan.
- Tags d'images bases sur le numero de build.

## Information Disclosure

Risque : fuite de secrets, tokens, cles privees ou informations sensibles.

Controles :

- Gitleaks dans le pipeline.
- `.gitignore` pour les cles et artefacts locaux.
- Injection des secrets par Jenkins credentials.
- Redaction des secrets dans les logs lorsque possible.

## Denial of Service

Risque : interruption du pipeline, du registre ou du serveur de deploiement.

Controles :

- Services Docker Compose isoles.
- Cache Trivy persistant.
- Pipeline par stages pour isoler les erreurs.
- Redemarrage automatique des services locaux critiques.

## Elevation of Privilege

Risque : un utilisateur ou processus obtient des privileges superieurs via le
socket Docker, Jenkins ou le registre.

Controles :

- Limiter l'acces au socket Docker.
- Restreindre les credentials Jenkins.
- Utiliser RBAC Harbor en cible.
- Eviter l'execution de secrets dans des scripts non controles.

## Risques residuels

- Le montage du socket Docker dans Jenkins reste sensible.
- Le registre local de demonstration ne remplace pas les controles RBAC Harbor.
- La signature Cosign necessite une gestion stricte des cles.
- Les scans ne garantissent pas l'absence totale de vulnerabilites.
