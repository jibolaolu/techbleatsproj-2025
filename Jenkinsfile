pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'  // Change to your AWS region
        TERRAFORM_DIR = 'terraform/'  // Change to the directory containing your Terraform code
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo 'Checking out source code...'
                    checkout scm
                }
            }
        }

        stage('Initialize Terraform') {
            steps {
                script {
                    dir(TERRAFORM_DIR) {
                        echo 'Initializing Terraform...'
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    dir(TERRAFORM_DIR) {
                        echo 'Running Terraform Plan...'
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('User Confirmation') {
            steps {
                script {
                    def userInput = input(
                        id: 'applyApproval',
                        message: 'Do you want to apply the Terraform changes?',
                        parameters: [choice(name: 'Proceed', choices: ['Yes', 'No'], description: 'Select Yes to proceed with apply')]
                    )
                    if (userInput == 'No') {
                        echo 'User chose not to proceed with Terraform apply. Exiting pipeline.'
                        currentBuild.result = 'ABORTED'
                        error('Pipeline stopped by user decision.')
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    dir(TERRAFORM_DIR) {
                        echo 'Applying Terraform changes...'
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Terraform infrastructure deployed successfully!'
        }
        failure {
            echo 'Terraform execution failed!'
        }
    }
}
