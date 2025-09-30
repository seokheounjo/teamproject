pipeline {
  agent any

  environment {
    GITHUB_OWNER = "seokheounjo"
    REGISTRY = "ghcr.io/${GITHUB_OWNER}"
    IMAGE = "${env.REGISTRY}/dev-calendar"
    SHA = "${env.GIT_COMMIT}"
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'python -m pip install --upgrade pip && pip install -r requirements.txt pytest'
        sh 'pytest -q'
      }
    }

    stage('Docker Build & Push') {
      environment {
        DOCKER_CONFIG = "${env.WORKSPACE}/.docker"
      }
      steps {
        withCredentials([string(credentialsId: 'github-token', variable: 'CR_PAT')]) {
          sh 'mkdir -p ${DOCKER_CONFIG}'
          sh 'echo $CR_PAT | docker login ghcr.io -u ${GITHUB_OWNER} --password-stdin'
          sh 'docker build --build-arg VERSION=${SHA} -t ${IMAGE}:latest -t ${IMAGE}:${SHA} .'
          sh 'docker push ${IMAGE}:latest'
          sh 'docker push ${IMAGE}:${SHA}'
        }
      }
    }

    stage('Bump Manifests (Kustomize)') {
      steps {
        sh 'cd deploy/k8s/overlays/dev && kustomize edit set image app=${IMAGE}:${SHA}'
        sh 'cd deploy/k8s/overlays/prod && kustomize edit set image app=${IMAGE}:${SHA}'
        withCredentials([string(credentialsId: 'github-token', variable: 'GIT_TOKEN')]) {
          sh """
            git config user.name "jenkins"
            git config user.email "jenkins@local"
            git add -A
            git commit -m "chore(ci): bump image to ${SHA}" || echo "No changes"
            git push https://${GIT_TOKEN}@github.com/${GITHUB_OWNER}/teamproject.git HEAD:master
          """
        }
      }
    }
  }
}

