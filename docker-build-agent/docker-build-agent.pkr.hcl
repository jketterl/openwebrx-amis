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

source "amazon-ebs" "debian-amd64" {
  ami_name              = "openwebrx-jenkins-agent-amd64"
  force_deregister      = true
  force_delete_snapshot = true
  instance_type         = "t2.micro"
  region                = "eu-central-1"
  source_ami_filter {
    filters = {
      name                = "debian-12-amd64-20231013-1532"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["136693071363"]
  }
  ssh_username = "admin"
}

source "amazon-ebs" "debian-arm64" {
  ami_name              = "openwebrx-jenkins-agent-arm64"
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
}

build {
  name = "docker-build-agent"
  sources = [
    "source.amazon-ebs.debian-amd64",
    "source.amazon-ebs.debian-arm64"
  ]
  provisioner "shell" {
    inline = [
      "sudo useradd jenkins",
      "sudo mkdir -p /home/jenkins/.ssh",
      "sudo sh -c \"echo '${var.jenkins_ssh_key}' > /home/jenkins/.ssh/authorized_keys\"",
      "sudo chown jenkins: /home/jenkins",
      "sudo apt-get update",
      "sudo apt-get install -y default-jre-headless",
      "sudo apt-get install -y ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli",
      "sudo usermod -aG docker jenkins",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}
