# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "docker-lab"

  config.vm.network "forwarded_port", guest: 9000, host: 9000, auto_correct: true
  config.vm.network "forwarded_port", guest: 8080, host: 8080, auto_correct: true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "docker-lab"
    vb.memory = 4096
    vb.cpus = 2
  end

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    set -e

    apt-get update
    apt-get install -y ca-certificates curl gnupg git unzip nodejs npm

    if ! command -v docker >/dev/null 2>&1; then
      curl -fsSL https://get.docker.com | sh
    fi

    systemctl enable docker
    systemctl start docker

    usermod -aG docker vagrant
  SHELL
end