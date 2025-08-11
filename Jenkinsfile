pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        PLAYBOOK_FILE = 'install_docker.yaml'
        PEM_FILE = credentials('ansible-ssh-key')
        SECRET_NAME = 'docker_credentials'
        REGION = 'us-east-1'
    }

    stages {
        stage ('Clone Github Repository') {
            steps{
               checkout scm
            } 
        }

        stage('Check User') {
            steps {
               sh 'whoami'
            }
        }

        stage ('Run Ansible Playbook') {
            steps{
                withCredentials([file(credentialsId: 'ansible-ssh-key', variable: 'PEM_FILE')]) {
                  sh '''
                    set -e  # Fail if any command fails
                    chmod 600 \$PEM_FILE

                    # Get the public IP of the EC2 instance using AWS CLI and a tag or name filter
                    INSTANCE_ID=$(aws ec2 describe-instances \
                    --filters "Name=tag:Name,Values=CICDServer" "Name=instance-state-name,Values=running" \
                    --query "Reservations[0].Instances[0].InstanceId" --output text )

                    PUBLIC_IP=$(aws ec2 describe-instances \
                    --instance-ids $INSTANCE_ID \
                    --query "Reservations[0].Instances[0].PublicIpAddress" \
                    --output text)

                    echo "[all]" > inventory.ini
                    echo "target1 ansible_host=\${PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=\$PEM_FILE" >> inventory.ini

                    echo "Pinging EC2 Instance.."
                    ansible -i inventory.ini all -m ping

                    echo "Running Ansible Playbook to install Docker.."
                    ansible-playbook -i inventory.ini \${PLAYBOOK_FILE} --private-key \$PEM_FILE 
                  '''
                }
            }
         }

        stage ('Docker Login') {
            steps{
                script{
                    // Fetch secret from AWS Secrets Manager
                    def dockerCreds = sh(
                        script:"aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --region ${REGION} --query SecretString --output text",
                        returnStdout: true
                    ).trim()

                    // Parse the JSON String via Secrets Manager
                    def creds = readJSON text: dockerCreds
                    env.DOCKER_USERNAME = creds.username
                    env.DOCKER_PASSWORD = creds.password

                    //Perform secure Docker Login using password
                    sh '''
                        echo "${DOCKER_PASSWORD}" |  docker login -u "${DOCKER_USERNAME}" --password-stdin
                    '''
                } 
            }
        }

        stage ('Build and Push Docker Image') {
            steps{
                sh '''
                    docker build -t ${DOCKER_USERNAME}/myapp:latest .
                    docker push ${DOCKER_USERNAME}/myapp:latest
                '''
                }
            }
              
        /* stage('Ping localhost') {
            steps {
                sh "ansible -i ${INVENTORY_FILE} --list-hosts all"
                sh "ansible -i ${INVENTORY_FILE} all -m ping"
            }
        } */

        /* stage('Run Ansible Playbook') {
            steps {
                sh "ansible-playbook -i ${INVENTORY_FILE} ${PLAYBOOK_FILE} --become"
            }
        } */   
        
        stage ('Initialize Terraform Code') {
            steps{
               dir('terraform') {
                  sh 'terraform init'
               }
            } 
        }
        stage ('Validate the Configuration') {
            steps{
               dir('terraform') {
                  sh 'terraform validate'
               }
            } 
        }
        stage ('Execute Plan') {
            steps{
               dir('terraform') {
                  sh 'terraform plan'
               }
            } 
        }
        stage ('Run Apply to create AWS Resource') {
            steps{
               dir('terraform') {
                  sh 'terraform apply --auto-approve'
               }
            } 
        }
    }
}
