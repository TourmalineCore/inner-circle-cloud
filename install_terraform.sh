# Use Yandex Cloud mirror for Terraform
cat << EOF > ~/.terraformrc
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF

# Terraform installation
arch=$(dpkg --print-architecture)
version=1.13.4

wget https://hashicorp-releases.yandexcloud.net/terraform/${version}/terraform_${version}_linux_${arch}.zip

sudo unzip terraform_${version}_linux_${arch}.zip -d /usr/local/bin/ -x "LICENSE.txt"

rm terraform_${version}_linux_${arch}.zip