pipeline { 
    agent any
    
    tools {
        maven 'maven3'
        jdk 'jdk17'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    
    stages {
        
        stage('Compile') {
            steps {
            sh  "mvn test"
            }
        }

        stage('Trivy FS Scan') {
            steps {
            sh  "trivy fs --format table -o fs.html ."
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                withSonarQubeEnv('sonarqube-server') {
                    sh ''' ${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=Blogging-App \
                            -Dsonar.projectName=Blogging-App \
                            -Dsonar.java.binaries=. '''
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonarqube-token'
                }
            }
        }
        
        stage('Build') {
            steps {
                sh "mvn clean package"
            }
        }

        stage('OWASP Dependency-Check') {
            steps {
                dependencyCheck additionalArguments: '--scan target/ --format HTML --nvdApiKey 655b27ba-21f9-4421-bcac-2084ac284dd6', odcInstallation: 'dependency-check' 
                dependencyCheckPublisher pattern:'**/dependency-check-report.xml'
            }
        }

        stage('Push Artifact to Nexus') {
            steps {
                
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker image build -t blogging-app ."
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL waldara/blogging-app:1.0'
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'fb7a0a85-c414-46f1-8718-91bd5a3eb411') {
                        sh 'docker image tag blogging-app waldara/blogging-app:1.0'
                        sh 'docker image push waldara/blogging-app:1.0'
                    }
                }
            }
        }


    }
}
