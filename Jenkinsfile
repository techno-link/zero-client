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
      }
    }
    stage('CREATE ISO') {
      steps {
        // dir('mender-convert') {
        //   sh './docker-build'
        //   sh 'mkdir -p input'
        // }
        sh '''
          xorriso -as mkisofs -r -V "Zero Client" \
              -cache-inodes -J -l \
              -isohybrid-mbr "mini-mbr.img" \
              -c boot.cat \
              -b isolinux.bin \
              -no-emul-boot -boot-load-size 4 -boot-info-table \
              -eltorito-alt-boot \
              -e boot/grub/efi.img \
              -no-emul-boot -isohybrid-gpt-basdat \
              -o "custom.iso" \
              "mini"
        '''
        sh 'ls -la'
      }
    }
  }

  // CLEANUP
  post { always { cleanWs() } }
}
