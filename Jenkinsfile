// pipeline {
//     agent any
//
//     environment {
//         AWS_REGION = 'eu-west-2'  // Change to your AWS region
//         TERRAFORM_DIR = './terraform/'  // Change to the directory containing your Terraform code
//     }
//
//     stages {
//         stage('Checkout Code') {
//             steps {
//                 script {
//                     echo 'Checking out source code...'
//                     checkout scm
//                 }
//             }
//         }
//
//         stage('Initialize Terraform') {
//             steps {
//                 withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
//                     script {
//                         dir(TERRAFORM_DIR) {
//                             echo 'Initializing Terraform...'
//                             sh '''
//                                 export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                                 export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
//                                 terraform init
//                             '''
//                         }
//                     }
//                 }
//             }
//         }
//
//         stage('Terraform Plan') {
//             steps {
//                 withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
//                     script {
//                         dir(TERRAFORM_DIR) {
//                             echo 'Running Terraform Plan...'
//                             sh '''
//                                 export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                                 export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
//                                 terraform plan  -var-file="dev.tfvars -out=tfplan
//                             '''
//                         }
//                     }
//                 }
//             }
//         }
//
//         stage('User Confirmation') {
//             steps {
//                 script {
//                     def userInput = input(
//                         id: 'applyApproval',
//                         message: 'Do you want to apply the Terraform changes?',
//                         parameters: [choice(name: 'Proceed', choices: ['Yes', 'No'], description: 'Select Yes to proceed with apply')]
//                     )
//                     if (userInput == 'No') {
//                         echo 'User chose not to proceed with Terraform apply. Exiting pipeline.'
//                         currentBuild.result = 'ABORTED'
//                         error('Pipeline stopped by user decision.')
//                     }
//                 }
//             }
//         }
//
//         stage('Terraform Apply') {
//             steps {
//                 withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
//                     script {
//                         dir(TERRAFORM_DIR) {
//                             echo 'Applying Terraform changes...'
//                             sh '''
//                                 export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
//                                 export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
//                                 terraform apply -auto-approve tfplan  -var-file="dev.tfvars
//                             '''
//                         }
//                     }
//                 }
//             }
//         }
//     }
//
//     post {
//         success {
//             echo 'Terraform infrastructure deployed successfully!'
//         }
//         failure {
//             echo 'Terraform execution failed!'
//         }
//     }
// }

pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-2'  // Change to your AWS region
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo 'Checking out source code...'
                    checkout([$class: 'GitSCM',
                        branches: [[name: '*/master']],
                        extensions: [[$class: 'WipeWorkspace']],
                        userRemoteConfigs: [[
                            credentialsId: 'github-credentials',
                            url: 'https://github.com/jibolaolu/techbleatsproj-2025.git'
                        ]]
                    ])
                }
            }
        }

        stage('Verify Terraform Files') {
            steps {
                script {
                    echo 'Listing repository root...'
                    sh 'ls -l'  // ✅ Ensure dev.tfvars and other Terraform files exist
                    sh 'cat dev.tfvars || echo "⚠️ WARNING: dev.tfvars NOT FOUND!"'
                }
            }
        }

        stage('Initialize Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo 'Initializing Terraform...'
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform init
                        """
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo 'Running Terraform Plan...'
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform plan -var-file=dev.tfvars -out=tfplan
                        """
                    }
                }
            }
        }

        stage('User Action: Apply or Destroy') {
            steps {
                script {
                    def userChoice = input(
                        id: 'actionChoice',
                        message: 'What action would you like to perform?',
                        parameters: [choice(name: 'Action', choices: ['Apply', 'Destroy', 'End Pipeline'], description: 'Select an action')]
                    )

                    if (userChoice == 'Apply') {
                        echo 'User chose to apply Terraform changes.'
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform apply -auto-approve -var-file=dev.tfvars tfplan
                        """
                    } else if (userChoice == 'Destroy') {
                        echo 'User chose to destroy the Terraform infrastructure.'
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform destroy -auto-approve -var-file=dev.tfvars
                        """
                    } else {
                        echo 'User chose to end the pipeline. Exiting...'
                        currentBuild.result = 'ABORTED'
                        error('Pipeline stopped by user decision.')
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Terraform execution completed successfully!'
        }
        failure {
            echo '❌ Terraform execution failed!'
        }
    }
}
