pipeline {
  agent any

  environment {
    IMAGE_NAME = 'devsecops/fastapi-demo'
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}"
    REGISTRY = 'localhost:8090'
    FULL_IMAGE = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Python tests') {
      steps {
        sh 'python3 -m venv --clear .venv'
        sh '. .venv/bin/activate && python -m pip install --upgrade pip && python -m pip install -r requirements-dev.txt'
        sh 'mkdir -p reports'
        sh '. .venv/bin/activate && python -m pytest --junitxml=reports/junit.xml'
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: 'reports/junit.xml'
        }
      }
    }

    stage('SAST') {
      steps {
        sh '. .venv/bin/activate && bandit -r src -q'
        sh 'mkdir -p .semgrep-home'
        sh '. .venv/bin/activate && HOME="$WORKSPACE/.semgrep-home" semgrep --metrics off --disable-version-check --config .semgrep.yml src tests_stable'
        sh 'gitleaks detect --source . --redact'
      }
    }

    stage('Build image') {
      steps {
        sh 'DOCKER_BUILDKIT=0 docker build -t "$FULL_IMAGE" .'
      }
    }

    stage('Trivy scan') {
      steps {
        sh './scripts/scan.sh "$FULL_IMAGE"'
      }
    }

    stage('Push image') {
      steps {
        sh '''
          docker push "$FULL_IMAGE" | tee push-output.txt
          DIGEST="$(awk '/digest:/ {print $3; exit}' push-output.txt)"
          if [ -z "$DIGEST" ]; then
            echo "Impossible de recuperer le digest depuis docker push"
            exit 1
          fi
          echo "${REGISTRY}/${IMAGE_NAME}@${DIGEST}" > image-digest.txt
          echo "Image digest: $(cat image-digest.txt)"
        '''
      }
    }

    stage('Prepare signing keys') {
      steps {
        sh '''
          if [ -z "${COSIGN_PASSWORD:-}" ]; then
            echo "COSIGN_PASSWORD doit etre defini dans l'environnement Jenkins."
            exit 1
          fi

          if [ ! -f cosign.key ] || [ ! -f cosign.pub ]; then
            docker run --rm \
              --user 0:0 \
              --network host \
              -e COSIGN_PASSWORD="$COSIGN_PASSWORD" \
              -v "$PWD":/work \
              -w /work \
              gcr.io/projectsigstore/cosign:latest generate-key-pair
          fi
        '''
      }
    }

    stage('Sign image') {
      steps {
        sh './scripts/sign.sh "$(cat image-digest.txt)"'
      }
    }

    stage('Verify signature') {
      steps {
        sh './scripts/verify.sh "$(cat image-digest.txt)"'
      }
    }

    stage('Deploy') {
      steps {
        sh '''
          IMAGE_TO_DEPLOY="$FULL_IMAGE" docker-compose -f docker-compose.deploy.yml up -d
          docker inspect -f '{{.State.Running}}' devsecops-api-deployed | grep true
          for attempt in 1 2 3 4 5; do
            if docker exec devsecops-api-deployed python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5).read().decode())"; then
              exit 0
            fi
            echo "Health check tentative $attempt echouee, nouvelle tentative..."
            sleep 2
          done
          exit 1
        '''
      }
    }
  }
}
