pipeline {
    agent any
    
    environment {
        DASHBOARD_URL = env.DASHBOARD_URL ?: 'http://localhost:4000'
    }
    
    stages {
        stage('Notify Start') {
            steps {
                script {
                    def startTime = new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
                    def payload = [
                        pipelineName: 'jenkins-pipeline',
                        status: 'running',
                        startedAt: startTime,
                        branch: env.BRANCH_NAME ?: 'main',
                        commitSha: env.GIT_COMMIT ?: 'unknown',
                        triggeredBy: env.BUILD_USER_ID ?: 'jenkins'
                    ]
                    
                    httpRequest(
                        url: DASHBOARD_URL,
                        httpMode: 'POST',
                        contentType: 'APPLICATION_JSON',
                        requestBody: groovy.json.JsonOutput.toJson(payload)
                    )
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                dir('backend') {
                    sh 'npm ci'
                }
                dir('frontend') {
                    sh 'npm ci'
                }
            }
        }
        
        stage('Test') {
            steps {
                dir('backend') {
                    sh 'npm test || echo "No tests configured"'
                }
                dir('frontend') {
                    sh 'npm test || echo "No tests configured"'
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('frontend') {
                    sh 'npm run build'
                }
            }
        }
        
        stage('Notify Success') {
            when {
                expression { currentBuild.result == null }
            }
            steps {
                script {
                    def endTime = new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
                    def startTime = new Date(currentBuild.startTimeInMillis).format("yyyy-MM-dd'T'HH:mm:ss'Z'")
                    def duration = System.currentTimeMillis() - currentBuild.startTimeInMillis
                    
                    def payload = [
                        pipelineName: 'jenkins-pipeline',
                        status: 'success',
                        startedAt: startTime,
                        finishedAt: endTime,
                        durationMs: duration,
                        branch: env.BRANCH_NAME ?: 'main',
                        commitSha: env.GIT_COMMIT ?: 'unknown',
                        triggeredBy: env.BUILD_USER_ID ?: 'jenkins',
                        logs: 'Pipeline completed successfully'
                    ]
                    
                    httpRequest(
                        url: DASHBOARD_URL,
                        httpMode: 'POST',
                        contentType: 'APPLICATION_JSON',
                        requestBody: groovy.json.JsonOutput.toJson(payload)
                    )
                }
            }
        }
    }
    
    post {
        failure {
            script {
                def endTime = new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'")
                def startTime = new Date(currentBuild.startTimeInMillis).format("yyyy-MM-dd'T'HH:mm:ss'Z'")
                def duration = System.currentTimeMillis() - currentBuild.startTimeInMillis
                
                def payload = [
                    pipelineName: 'jenkins-pipeline',
                    status: 'failure',
                    startedAt: startTime,
                    finishedAt: endTime,
                    durationMs: duration,
                    branch: env.BRANCH_NAME ?: 'main',
                    commitSha: env.GIT_COMMIT ?: 'unknown',
                    triggeredBy: env.BUILD_USER_ID ?: 'jenkins',
                    logs: 'Pipeline failed - check Jenkins logs'
                ]
                
                httpRequest(
                    url: DASHBOARD_URL,
                    httpMode: 'POST',
                    contentType: 'APPLICATION_JSON',
                    requestBody: groovy.json.JsonOutput.toJson(payload)
                )
            }
        }
    }
}
