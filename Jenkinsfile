pipeline {
  agent any

  environment {
    ACR_LOGIN_SERVER = credentials('acr-login-server') // optional; or plain env var
    ACR_USERNAME     = credentials('acr-username')
    ACR_PASSWORD     = credentials('acr-password')
    SONAR_LOGIN      = credentials('sonar-token')
    SONAR_HOST_URL   = "${SONAR_HOST_URL}"   // supply as a global env or Jenkins parameter
    ACR_REPO         = "${ACR_REPO}"         // e.g. profile-site
    GIT_CREDENTIALS_ID = "${GIT_CREDENTIALS_ID}" // e.g. git-creds
    IMAGE_TAG        = "${env.BUILD_NUMBER}"
    FULL_IMAGE       = "${ACR_LOGIN_SERVER}/${ACR_REPO}:${IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('SonarQube Scan') {
      steps {
        sh '''
          if command -v sonar-scanner >/dev/null 2>&1; then
            sonar-scanner \
              -Dsonar.host.url="$SONAR_HOST_URL" \
              -Dsonar.login="$SONAR_LOGIN"
          else
            echo "sonar-scanner not found; skipping (install SonarScanner CLI or Jenkins Sonar plugin)."
          fi
        '''
      }
    }

    stage('Docker Build & Push to ACR') {
      steps {
        sh '''
          echo "$ACR_PASSWORD" | docker login "$ACR_LOGIN_SERVER" -u "$ACR_USERNAME" --password-stdin
          docker build -t "$FULL_IMAGE" .
          docker push "$FULL_IMAGE"
        '''
      }
    }

    stage('Update Kustomize Image Tag (GitOps)') {
      steps {
        sh '''
          cd deploy/overlays/prod
          if command -v kustomize >/dev/null 2>&1; then
            kustomize edit set image profile-site="$FULL_IMAGE"
          else
            # Fallback: simple in-place edit of kustomization.yaml
            sed -i.bak "s|newName:.*|newName: ${ACR_LOGIN_SERVER}/${ACR_REPO}|" kustomization.yaml || true
            sed -i.bak "s|newTag:.*|newTag: ${IMAGE_TAG}|" kustomization.yaml || true
          fi
          cd ../../..
        '''
        script {
          withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIALS_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
            sh '''
              git config user.email "ci@local"
              git config user.name "jenkins-ci"
              git add deploy/overlays/prod/kustomization.yaml
              git commit -m "ci: update image tag to ${IMAGE_TAG}"
              REPO_URL=$(git config --get remote.origin.url)
              if echo "$REPO_URL" | grep -q '@'; then
                # already has credentials
                git push origin HEAD:main
              else
                # inject credentials
                REPO_URL_AUTH=$(echo "$REPO_URL" | sed "s#https://#https://${GIT_USER}:${GIT_PASS}@#")
                git push "$REPO_URL_AUTH" HEAD:main
              fi
            '''
          }
        }
      }
    }

    stage('(Optional) Argo CD Sync') {
      when { expression { return env.ARGOCD_SERVER && env.ARGOCD_AUTH_TOKEN } }
      steps {
        sh '''
          # If AutoSync is disabled, you can trigger a manual sync via Argo CD CLI/API.
          # Example using CLI (requires argocd CLI installed and network access):
          # argocd login "$ARGOCD_SERVER" --sso || true
          # argocd app sync profile-site --grpc-web
          echo "Argo CD manual sync stage placeholder."
        '''
      }
    }
  }

  post {
    always {
      sh 'docker logout || true'
    }
  }
}
