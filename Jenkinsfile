pipeline {
    agent any

    environment {
        GIT = 'http://name.git'
        DOCKER_IMAGE = 'harbor/tag'
        HARBOR_BASE_URL = credentials('harbor_base_url')
        // https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#usernames-and-passwords
        // username: HARBOR_AUTH_USR
        // password: HARBOR_AUTH_PSW
        HARBOR_AUTH = credentials('harbor_auth')
        WECOM_WEBHOOK = 'httpx://'
    }

    stages {
        stage('Clone and Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: '${BRANCH_NAME}']],
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: '',
                        url: "${GIT}"
                    ]]
                )
                script {
                    BUILD_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build --network=host -t ${DOCKER_IMAGE}:${BUILD_TAG} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'harbor_auth', usernameVariable: 'HARBOR_AUTH_USR', passwordVariable: 'HARBOR_AUTH_PSW')]) {
                        sh "docker login -u ${HARBOR_AUTH_USR} -p ${HARBOR_AUTH_PSW} ${HARBOR_BASE_URL}"
                        sh "docker push ${DOCKER_IMAGE}:${BUILD_TAG}"
                    }
                }
            }

            post {
                success {
                    echo 'Push Docker Image Success and remove local image'
                    sh "docker rmi ${DOCKER_IMAGE}:${BUILD_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh "sed -i 's/<BUILD_TAG>/${BUILD_TAG}/g' ${deploymentFile}"
                    sh 'kubectl apply -f configmap.yaml'
                    sh "kubectl apply -f ${deploymentFile}"
                }
            }
        }
    }

    post {
        success {
            qyWechatNotification failNotify: true, webhookUrl: "${WECOM_WEBHOOK}", moreInfo:'额外的信息'
        }

        failure {
            qyWechatNotification failNotify: true, webhookUrl: "${WECOM_WEBHOOK}", moreInfo:'额外的信息'
        }
    }
}
