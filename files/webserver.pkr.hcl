data "amazon-ami" "aws_ami_id" {
  filters = {
    name                = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["137112412989"]
  region      = "eu-central-1"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "ami_id" {
  ami_name                    = "website_ami_${local.timestamp}"
  associate_public_ip_address = "true"
  instance_type               = "t3.large"
  region                      = "eu-central-1"
  source_ami                  = "${data.amazon-ami.aws_ami_id.id}"
  ssh_username                = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.ami_id"]

  provisioner "shell" {
    inline         = ["sudo yum -y update",
                      "sudo yum install -y php-fpm php-mysql mysql amazon-cloudwatch-agent",
                      "sudo amazon-linux-extras install -y nginx1"]
    inline_shebang = "/bin/bash -e"
  }

  provisioner "file" {
    source      = "nginx_logs.json"
    destination = "/tmp/nginx_logs.json"
  }

  provisioner "shell" {
    inline         = [ <<EOS
sudo echo "map \$http_user_agent \$keeplog {
\"ELB-HealthChecker/2.0\" 0;
default 1;
}
server {
listen   8080;
error_log /var/log/nginx/web_error.log;
access_log /var/log/nginx/web_access.log combined if=\$keeplog;
root /srv/data;
index index.php;
location / {
try_files \$uri \$uri/ /index.php;
}
# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
location ~ \.php$ {
try_files \$uri =404;
fastcgi_pass 127.0.0.1:9000;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
include fastcgi_params;
}
}" > /tmp/default.conf
EOS
    ]
    inline_shebang = "/bin/bash -e"
  }

  provisioner "shell" {
    inline         = ["sudo mv /tmp/default.conf /etc/nginx/conf.d/default.conf",
                      "sudo mv /tmp/nginx_logs.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/nginx_logs.json",
                      "sudo systemctl enable nginx",
                      "sudo systemctl enable php-fpm",
                      "sudo systemctl enable amazon-cloudwatch-agent",
                      "sudo mkdir /srv/data"]
    inline_shebang = "/bin/bash -e"
  }

}
