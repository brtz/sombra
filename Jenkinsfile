pipeline {
    agent { docker 'ruby:2.6-alpine' }
    stages {
        stage("prebuild") {
            steps {
                checkout scm
                sh("bundle install --clean --path ~/.gem")   
            }
        }
        stage("docgen") {
            steps {
                sh("yard doc")
            }
        }
    }
}
