pipeline { 
    agent any
    tools {
        maven 'maven3'
        jdk 'jdk17'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        IMAGE_TAG = "v1.0"
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs() 
                
            } 
            
        }
        
        stage('Git Checkout') {
            steps {
            git branch: 'main', url: 'https://github.com/waldra/Blogging-App.git'
            }
        }
        
        stage('Compile') {
            steps {
            sh  "mvn clean test"
            }
        }

        stage('Trivy FS Scan') {
            steps {
            sh   "trivy fs --security-checks vuln,config --severity HIGH,CRITICAL --format table -o fs.html ."
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
        
        stage('Build') {
            steps {
                sh "mvn clean package"
            }
        }

        stage('OWASP Dependency-Check') {
            steps {
                dependencyCheck additionalArguments: '--scan target/ --format XML --nvdApiKey 655b27ba-21f9-4421-bcac-2084ac284dd6', odcInstallation: 'dependency-check' 
                dependencyCheckPublisher pattern:'**/dependency-check-report.xml'
            }
        }
        
        stage('Push Artifact to Nexus') {
            steps {
                script {
                    withMaven(globalMavenSettingsConfig: 'maven-settings', jdk: 'jdk17', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                        sh 'mvn clean deploy'
                    }    
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh "docker image build -t bloggingapp ."
                sh 'docker image tag blogging-app waldara/bloggingapp:${IMAGE_TAG}'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL waldara/bloggingapp:${IMAGE_TAG}'
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh 'docker image push waldara/bloggingapp:${IMAGE_TAG}'
                    }
                }
            }
        }
        
        stage('Update YAML manifest in CD Repo') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'git-cred', gitToolName: 'Default')]) {
                    sh '''
                       git clone https://github.com/waldra/Blogging-App-CD.git
                       cd Blogging-App-CD
                       repo_dir=$(pwd)
                       sed -i 's|image: waldara/bloggingapp.*|image: waldara/bloggingapp:'${IMAGE_TAG}'|' ${repo_dir}/app-manifest/deployment.yaml
                       '''
                    
                    sh '''
                       cd Blogging-App-CD
                       git config user.name "Jenkins"
                       git config user.email "Jenkins@gmail.com"
                       
                       git add app-manifest/deployment.yaml
                       git commit -m "Update image tag to ${IMAGE_TAG}"
                       git push origin main
                       '''
                }
            }
        }
    }    
}
