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
        stage('User Selection: Environment') {
            steps {
                script {
                    env.SELECTED_ENV = input(
                        id: 'environmentSelection',
                        message: 'Select the deployment environment:',
                        parameters: [
                            choice(name: 'Environment', choices: ['dev', 'prod'], description: 'Select the environment')
                        ]
                    )
                    env.TFVARS_FILE = "${env.SELECTED_ENV}.tfvars"  // Use the selected tfvars file
                    echo "User selected environment: ${env.SELECTED_ENV}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                script {
                    echo 'Checking out source code...'
                    checkout([$class: 'GitSCM',
                        branches: [[name: '*/master']],
                        extensions: [[$class: 'WipeWorkspace']],  // ✅ Ensure clean checkout
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
                    echo "Using Variables File: ${env.TFVARS_FILE}"
                    sh 'ls -l'  // ✅ Check if tfvars files exist
                    sh "cat ${env.TFVARS_FILE} || echo '⚠️ WARNING: ${env.TFVARS_FILE} NOT FOUND!'"
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
                        echo "Running Terraform Plan for ${env.SELECTED_ENV}..."
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform plan -var-file=${env.TFVARS_FILE} -out=tfplan
                        """
                    }
                }
            }
        }

        stage('User Selection: Apply or Destroy') {
            steps {
                script {
                    env.SELECTED_ACTION = input(
                        id: 'actionSelection',
                        message: 'Terraform Plan completed. Select Apply or Destroy:',
                        parameters: [
                            choice(name: 'Action', choices: ['Apply', 'Destroy'], description: 'Select Apply or Destroy')
                        ]
                    )
                    echo "User selected action: ${env.SELECTED_ACTION}"
                }
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    if (env.SELECTED_ACTION == 'Apply') {
                        echo "Applying Terraform for ${env.SELECTED_ENV}..."
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform apply -auto-approve -var-file=${env.TFVARS_FILE} tfplan
                        """
                    } else if (env.SELECTED_ACTION == 'Destroy') {
                        echo "Destroying Terraform for ${env.SELECTED_ENV}..."
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform destroy -auto-approve -var-file=${env.TFVARS_FILE}
                        """
                    } else {
                        echo "⚠️ Invalid action selected. Pipeline exiting."
                        currentBuild.result = 'ABORTED'
                        error('Pipeline stopped due to invalid action.')
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
