pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')    
    }

    stages {
        stage ('Clone Github Repository') {
            steps{
               checkout scm
            } 
        }
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