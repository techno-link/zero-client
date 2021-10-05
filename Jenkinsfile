// ---------------------------------------------------------------------------------------------------------------------
// PIPELINE
// ---------------------------------------------------------------------------------------------------------------------
pipeline {
  agent { label 'mender' }
  stages {
    stage('GET TOOLS') {
      steps {
        sh 'yum install -y p7zip p7zip-plugins xorriso'
      }
    }
    stage('GET ISO') {
      steps {
        sh 'wget http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/mini.iso'
        sh 'dd if="mini.iso" bs=1 count=466 of="mini-mbr.img"'
        sh '7z x mini.iso -omini'
        sh 'ls -la'
        // dir('mender-convert') {
        //   sh './docker-build'
        //   sh 'mkdir -p input'
        // }
      }
    }
    // stage('GET ISO') {
    //   steps {
    //     sh 'wget http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/mini.iso'
    //     sh 'dd if="mini.iso" bs=1 count=466 of="mini-mbr.img"'
    //     sh 'ls -la'
    //   }
    // }
  }

  // CLEANUP
  post { always { cleanWs() } }
}
