variable "jenkins_ssh_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBVPFD6WawyZFpZGbkNXhk2prn2/pt5JSrWMXMPPmsgNyQXVg3lxPlW7zZSMDJQqLP+mTC/qTyvgqhzc7vxn0LwgkMTCCsEgqSolj6qgbeVOwgCKpukNCO8132XIKLki622vhCXglpCQPOgrOH9u3wU9ipzrMlpraJ9pFDuSQObDSWxFIS2lph1/G9Ox7b3/OG1Pa/dDqWj9xFLH7gB4cS95GG3ncwHPHm2Pd8uvlGoWXoL9LX2znN1Noce9j0dLH4deAJjWg8oDlVXjvfwAlOwZ3hrYl9nFs925kqzd8fKOi6Wlam/Vg1AcTcaFt0jv9wudAoNWF+ise1fMdeDqPR jakob@gamer"
}

packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "debian-arm64" {
  ami_name              = "openwebrx-jenkins-agent-debian-arm64"
  force_deregister      = true
  force_delete_snapshot = true
  instance_type         = "a1.medium"
  region                = "eu-central-1"
  source_ami_filter {
    filters = {
      name                = "debian-12-arm64-20231013-1532"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["136693071363"]
  }
  ssh_username = "admin"
  ami_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 20
    delete_on_termination = true
  }
}

build {
  name = "debian-build-agent"
  sources = [
    "source.amazon-ebs.debian-arm64"
  ]
  provisioner "shell" {
    inline = [
      "sudo useradd jenkins",
      "sudo mkdir -p /home/jenkins/.ssh",
      "sudo sh -c \"echo '${var.jenkins_ssh_key}' > /home/jenkins/.ssh/authorized_keys\"",
      "sudo chown jenkins: /home/jenkins",
      "sudo sh -c \" echo 'jenkins ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/010_jenkins-nopasswd\"",
      "sudo apt-get update",
      "sudo apt-get install -y default-jre-headless",
      "sudo apt-get install -y git coreutils quilt parted debootstrap zerofree zip dosfstools libarchive-tools libcap2-bin grep rsync xz-utils file git curl bc kpartx gpg pigz qemu-user-static xxd",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}
