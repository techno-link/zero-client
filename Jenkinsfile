// ---------------------------------------------------------------------------------------------------------------------
// PIPELINE
// ---------------------------------------------------------------------------------------------------------------------
pipeline {
  agent { label 'mender' }
  stages {
    stage('Get Ubuntu Mini Iso') {
      steps {
        sh 'wget http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/mini.iso'
      }
    }
  }


  // CLEANUP
  post { always { cleanWs() } }
}
