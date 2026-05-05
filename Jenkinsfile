pipeline {
  agent any

  environment {
    IMAGE_NAME = 'devsecops/fastapi-demo'
    IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}"
    REGISTRY = 'localhost:8090'
    FULL_IMAGE = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    API_SECRET_TOKEN = credentials('api-secret-token')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Python tests') {
      steps {
        sh 'python3 -m venv .venv'
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
        sh '. .venv/bin/activate && semgrep --config auto src tests_stable'
        sh 'gitleaks detect --source . --no-git --redact'
      }
    }

    stage('Build image') {
      steps {
        sh 'docker build -t "$FULL_IMAGE" .'
      }
    }

    stage('Trivy scan') {
      steps {
        sh './scripts/scan.sh "$FULL_IMAGE"'
      }
    }

    stage('Push image') {
      steps {
        sh 'docker push "$FULL_IMAGE"'
      }
    }
  }
}
