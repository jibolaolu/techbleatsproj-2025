// pipeline {
//     agent any
//
//     environment {
//         AWS_REGION = 'eu-west-2'
//         S3_BUCKET = "seunadio-tfstate"
//         STATE_FILE_KEY = "techbleats/infra.tfstate"
//     }
//
//     stages {
//         stage('User Selection: Environment') {
//             steps {
//                 script {
//                     env.SELECTED_ENV = input(
//                         id: 'environmentSelection',
//                         message: 'Select the deployment environment:',
//                         parameters: [
//                             choice(name: 'Environment', choices: ['dev', 'prod'], description: 'Select the environment')
//                         ]
//                     )
//                     env.TFVARS_FILE = "${env.SELECTED_ENV}.tfvars"
//                     echo "User selected environment: ${env.SELECTED_ENV}"
//                 }
//             }
//         }
//
//         stage('Checkout Code') {
//             steps {
//                 script {
//                     echo 'Checking out source code...'
//                     checkout([$class: 'GitSCM',
//                         branches: [[name: '*/master']],
//                         extensions: [[$class: 'WipeWorkspace']],
//                         userRemoteConfigs: [[
//                             credentialsId: 'github-credentials',
//                             url: 'https://github.com/jibolaolu/techbleatsproj-2025.git'
//                         ]]
//                     ])
//                 }
//             }
//         }
//
//         stage('Check for Existing Terraform State') {
//             steps {
//                 withCredentials([[
//                     $class: 'AmazonWebServicesCredentialsBinding',
//                     credentialsId: 'aws_credentials',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 ]]) {
//                     script {
//                         echo "🔍 Checking if Terraform state exists in S3..."
//                         def stateExists = sh(
//                             script: """
//                                 export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
//                                 export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
//                                 aws s3 ls s3://${S3_BUCKET}/${STATE_FILE_KEY} | wc -l
//                             """,
//                             returnStdout: true
//                         ).trim()
//
//                         if (stateExists == "1") {
//                             echo "✅ Statefile exists in S3. Terraform is tracking resources."
//                             env.STATEFILE_EXISTS = "true"
//                         } else {
//                             echo "⚠️ No statefile found in S3. Terraform will start fresh."
//                             env.STATEFILE_EXISTS = "false"
//                         }
//                     }
//                 }
//             }
//         }
//
//         stage('Terraform Init & Refresh') {
//             steps {
//                 withCredentials([[
//                     $class: 'AmazonWebServicesCredentialsBinding',
//                     credentialsId: 'aws_credentials',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 ]]) {
//                     script {
//                         echo 'Initializing Terraform...'
//                         sh """
//                             export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
//                             export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
//                             terraform init
//                         """
//
//                         if (env.STATEFILE_EXISTS == "true") {
//                             echo "Refreshing Terraform state..."
//                             sh "terraform refresh -var-file=${env.TFVARS_FILE}"
//                         }
//                     }
//                 }
//             }
//         }
//
//         stage('User Selection: Action (Plan, Plan and Approve, Destroy)') {
//             steps {
//                 script {
//                     env.SELECTED_ACTION = input(
//                         id: 'actionSelection',
//                         message: 'What action would you like to perform?',
//                         parameters: [
//                             choice(name: 'Action', choices: ['Plan', 'Plan and Approve', 'Destroy'], description: 'Select an action')
//                         ]
//                     )
//                     echo "User selected action: ${env.SELECTED_ACTION}"
//                 }
//             }
//         }
//
//         stage('Terraform Plan') {
//             when {
//                 expression { env.SELECTED_ACTION == 'Plan' || env.SELECTED_ACTION == 'Plan and Approve' }
//             }
//             steps {
//                 withCredentials([[
//                     $class: 'AmazonWebServicesCredentialsBinding',
//                     credentialsId: 'aws_credentials',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 ]]) {
//                     script {
//                         echo "Running Terraform Plan for ${env.SELECTED_ENV}..."
//                         sh """
//                             export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
//                             export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
//                             terraform plan -var-file=${env.TFVARS_FILE} -out=tfplan
//                         """
//
//                         if (env.SELECTED_ACTION == 'Plan and Approve') {
//                             env.APPLY_AFTER_PLAN = input(
//                                 id: 'applyAfterPlan',
//                                 message: 'Terraform Plan completed. Do you want to approve and apply the changes?',
//                                 parameters: [choice(name: 'Proceed', choices: ['Yes', 'No'], description: 'Select Yes to apply or No to cancel')]
//                             )
//                         }
//                     }
//                 }
//             }
//         }
//
//         stage('Terraform Apply') {
//             when {
//                 expression { env.SELECTED_ACTION == 'Plan and Approve' && env.APPLY_AFTER_PLAN == 'Yes' }
//             }
//             steps {
//                 withCredentials([[
//                     $class: 'AmazonWebServicesCredentialsBinding',
//                     credentialsId: 'aws_credentials',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 ]]) {
//                     script {
//                         echo "Applying Terraform for ${env.SELECTED_ENV}..."
//                         sh """
//                             export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
//                             export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
//                             terraform apply -auto-approve tfplan
//                         """
//                     }
//                 }
//             }
//         }
//
//         stage('Terraform Destroy') {
//             when {
//                 expression { env.SELECTED_ACTION == 'Destroy' }
//             }
//             steps {
//                 withCredentials([[
//                     $class: 'AmazonWebServicesCredentialsBinding',
//                     credentialsId: 'aws_credentials',
//                     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
//                     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
//                 ]]) {
//                     script {
//                         if (env.STATEFILE_EXISTS == "true") {
//                             echo "Destroying Terraform for ${env.SELECTED_ENV}..."
//                             sh """
//                                 export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
//                                 export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
//                                 terraform refresh
//                                 terraform destroy -auto-approve -var-file=${env.TFVARS_FILE}
//                             """
//                         } else {
//                             echo "⚠️ No Terraform statefile found. Nothing to destroy."
//                         }
//                     }
//                 }
//             }
//         }
//
//
//     post {
//         success {
//             echo '✅ Terraform execution completed successfully!'
//         }
//         failure {
//             echo '❌ Terraform execution failed!'
//         }
//     }
// }

pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-2'
        S3_BUCKET = "seunadio-tfstate"
        STATE_FILE_KEY = "techbleats/infra.tfstate"
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
                    env.TFVARS_FILE = "${env.SELECTED_ENV}.tfvars"
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
                        extensions: [[$class: 'WipeWorkspace']],
                        userRemoteConfigs: [[
                            credentialsId: 'github-credentials',
                            url: 'https://github.com/jibolaolu/techbleatsproj-2025.git'
                        ]]
                    ])
                }
            }
        }

        stage('Check for Existing Terraform State & Lock') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "🔍 Checking if Terraform state exists and if it's locked..."

                        def stateExists = sh(
                            script: """
                                export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                                aws s3 ls s3://${S3_BUCKET}/${STATE_FILE_KEY} | wc -l
                            """,
                            returnStdout: true
                        ).trim()

                        if (stateExists == "1") {
                            echo "✅ Statefile exists in S3."
                            env.STATEFILE_EXISTS = "true"

                            def lockCheck = sh(
                                script: """
                                    export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                                    aws dynamodb scan --table-name terraform-states-table --query "Count"
                                """,
                                returnStdout: true
                            ).trim()

                            if (lockCheck != "0") {
                                echo "🚨 Terraform state is locked! Running 'terraform init -lock=false' to unlock."
                                sh """
                                    terraform init -lock=false
                                """
                            } else {
                                echo "✅ No lock detected. Proceeding as normal."
                            }
                        } else {
                            echo "⚠️ No statefile found in S3. Terraform will start fresh."
                            env.STATEFILE_EXISTS = "false"
                        }
                    }
                }
            }
        }

        stage('Terraform Init & Refresh') {
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

                        if (env.STATEFILE_EXISTS == "true") {
                            echo "Refreshing Terraform state..."
                            sh "terraform refresh -var-file=${env.TFVARS_FILE}"
                        }
                    }
                }
            }
        }

        stage('User Selection: Action (Plan, Plan and Approve, Destroy)') {
            steps {
                script {
                    env.SELECTED_ACTION = input(
                        id: 'actionSelection',
                        message: 'What action would you like to perform?',
                        parameters: [
                            choice(name: 'Action', choices: ['Plan', 'Plan and Approve', 'Destroy'], description: 'Select an action')
                        ]
                    )
                    echo "User selected action: ${env.SELECTED_ACTION}"
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { env.SELECTED_ACTION == 'Plan' || env.SELECTED_ACTION == 'Plan and Approve' }
            }
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

                        if (env.SELECTED_ACTION == 'Plan and Approve') {
                            env.APPLY_AFTER_PLAN = input(
                                id: 'applyAfterPlan',
                                message: 'Terraform Plan completed. Do you want to approve and apply the changes?',
                                parameters: [choice(name: 'Proceed', choices: ['Yes', 'No'], description: 'Select Yes to apply or No to cancel')]
                            )
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { env.SELECTED_ACTION == 'Plan and Approve' && env.APPLY_AFTER_PLAN == 'Yes' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "Applying Terraform for ${env.SELECTED_ENV}..."
                        sh """
                            export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                            terraform apply -auto-approve tfplan
                        """
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { env.SELECTED_ACTION == 'Destroy' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        if (env.STATEFILE_EXISTS == "true") {
                            echo "Destroying Terraform for ${env.SELECTED_ENV}..."
                            sh """
                                export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                                terraform refresh -var-file=${env.TFVARS_FILE}
                                terraform destroy -auto-approve -var-file=${env.TFVARS_FILE}
                            """
                        } else {
                            echo "⚠️ No Terraform statefile found. Nothing to destroy."
                        }
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
