pipeline {
    agent any

    // Định nghĩa các công cụ cần dùng
    tools {
        // Phải cấu hình trong Manage Jenkins -> Tools -> Đặt tên là "NodeJS"
        nodejs 'NodeJS' 
        // Phải cấu hình trong Manage Jenkins -> Tools -> Đặt tên là "SonarQubeScanner"
    }

    environment {
        // --- CẤU HÌNH THÔNG TIN AWS ---
        // Thay bằng ID tài khoản AWS của bạn (Ví dụ: 891377xxxxx)
        AWS_ACCOUNT_ID = '322962301159' 
        
        // Region của bạn (Lúc nãy thấy bạn dùng ap-southeast-2)
        AWS_REGION     = 'ap-southeast-2'
        
        // Đường dẫn ECR (Tự động ghép từ ID và Region)
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        
        // Tên project (Dùng cho SonarQube)
        PROJECT_KEY    = 'eshelf'
        
        // Tên Server SonarQube đã cấu hình trong Jenkins System
        SONAR_SERVER   = 'sonarqube-server' 
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                checkout scm
                script {
                    // Lấy mã Commit ngắn (7 ký tự) để làm Tag cho Docker Image
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    echo "Current Commit: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('2. Install Dependencies') {
            steps {
                script {
                    // Danh sách các service Node.js cần cài npm install
                    // Lưu ý: ml-service là Python service, không cần npm install
                    def nodeServices = ['api-gateway', 'auth-service', 'book-service', 'user-service']
                    
                    nodeServices.each { service ->
                        echo "Installing npm dependencies for: ${service}"
                        // Lưu ý: Đảm bảo đường dẫn backend/services/... là đúng trong Code của bạn
                        dir("backend/services/${service}") {
                            sh 'npm install'
                        }
                    }
                    
                    // ml-service là Python service, dependencies sẽ được cài trong Dockerfile
                    echo "Skipping npm install for ml-service (Python service - dependencies handled in Dockerfile)"
                }
            }
        }
        
        stage('3. SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQubeScanner'
                    
                    // Gọi Server SonarQube (Token tự động được Jenkins lấy từ cấu hình System)
                    withSonarQubeEnv(SONAR_SERVER) {
                        sh """${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=${PROJECT_KEY} \
                        -Dsonar.projectName="eShelf Project" \
                        -Dsonar.sources=backend/services \
                        -Dsonar.host.url=http://sonarqube.sonarqube.svc.cluster.local:9000 \
                        -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/*.spec.js"""
                    }
                }
            }
        }

        stage('4. Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    // Đợi SonarQube trả kết quả. Nếu Fail -> Dừng pipeline ngay.
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('5. Login AWS ECR') {
            steps {
                script {
                    // Dùng credentials ID 'aws-credentials' đã tạo ở bước chuẩn bị
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET', usernameVariable: 'AWS_KEY')]) {
                        // Cấu hình AWS CLI tạm thời để login
                        sh """
                            export AWS_ACCESS_KEY_ID=${AWS_KEY}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET}
                            export AWS_DEFAULT_REGION=${AWS_REGION}
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        """
                    }
                }
            }
        }

        stage('6. Build & Push Docker Images') {
            steps {
                script {
                    def services = ['api-gateway', 'auth-service', 'book-service', 'user-service', 'ml-service']
                    
                    services.each { service ->
                        echo "Building & Pushing: ${service}"
                        
                        dir("backend/services/${service}") {
                            // 1. Build Image
                            sh "docker build -t ${ECR_REGISTRY}/${PROJECT_KEY}/${service}:${env.GIT_COMMIT_SHORT} ."
                            
                            // 2. Tag thêm bản 'latest'
                            sh "docker tag ${ECR_REGISTRY}/${PROJECT_KEY}/${service}:${env.GIT_COMMIT_SHORT} ${ECR_REGISTRY}/${PROJECT_KEY}/${service}:latest"
                            
                            // 3. Push lên ECR
                            sh "docker push ${ECR_REGISTRY}/${PROJECT_KEY}/${service}:${env.GIT_COMMIT_SHORT}"
                            sh "docker push ${ECR_REGISTRY}/${PROJECT_KEY}/${service}:latest"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Dọn dẹp Workspace sau khi chạy xong để tiết kiệm ổ cứng
            echo "Pipeline finished."
        }
        success {
            echo "SUCCESS: Code đã được quét và Image đã lên AWS ECR!"
        }
        failure {
            echo "FAILURE: Có lỗi xảy ra, vui lòng kiểm tra Console Output."
        }
    }
}

