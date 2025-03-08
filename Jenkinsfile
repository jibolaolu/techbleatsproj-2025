pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-2'
        S3_BUCKET = "seunadio-tfstate"  // ✅ Replace with your actual S3 bucket name
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

        stage('Check for Existing Terraform State') {
            steps {
                withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'aws_credentials',
                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "🔍 Checking if Terraform state exists in S3..."
                        def stateExists = sh(
                            script: """
                                export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                                aws s3 ls s3://${S3_BUCKET}/${STATE_FILE_KEY} | wc -l
                            """,
                            returnStdout: true
                        ).trim()

                        if (stateExists == "1") {
                            echo "✅ Statefile exists in S3. Terraform is tracking resources."
                            env.STATEFILE_EXISTS = "true"
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

        stage('User Selection: Action (Plan, Apply, Destroy)') {
            steps {
                script {
                    env.SELECTED_ACTION = input(
                        id: 'actionSelection',
                        message: 'What action would you like to perform?',
                        parameters: [
                            choice(name: 'Action', choices: ['Plan', 'Apply', 'Destroy'], description: 'Select Plan, Apply, or Destroy')
                        ]
                    )
                    echo "User selected action: ${env.SELECTED_ACTION}"
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { env.SELECTED_ACTION == 'Plan' }
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

                        // Ask user if they want to apply after a successful plan
                        env.APPLY_AFTER_PLAN = input(
                            id: 'applyAfterPlan',
                            message: 'Terraform Plan completed. Do you want to apply the changes?',
                            parameters: [choice(name: 'Proceed', choices: ['Yes', 'No'], description: 'Select Yes to apply or No to cancel')]
                        )
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { env.SELECTED_ACTION == 'Apply' || (env.SELECTED_ACTION == 'Plan' && env.APPLY_AFTER_PLAN == 'Yes') }
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
                script {
                    if (env.STATEFILE_EXISTS == "true") {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws_credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]]) {
                            echo "Destroying Terraform for ${env.SELECTED_ENV}..."
                            sh """
                                export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                                terraform destroy -auto-approve tfplan
                            """
                        }
                    } else {
                        echo "⚠️ No Terraform statefile found. Nothing to destroy."
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
