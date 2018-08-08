# The docker AMI
data "aws_ami" "bod_docker" {
  filter {
    name = "name"
    values = [
      "cyhy-docker-hvm-*-x86_64-ebs"
    ]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  owners = ["${data.aws_caller_identity.current.account_id}"] # This is us
  most_recent = true
}

# The docker EC2 instance
resource "aws_instance" "bod_docker" {
  ami = "${data.aws_ami.bod_docker.id}"
  instance_type = "${terraform.workspace == "production" || terraform.workspace == "planet_piss" ? "r4.4xlarge" : "t2.micro"}"
  ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id = "${aws_subnet.bod_private_subnet.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${terraform.workspace == "production" || terraform.workspace == "planet_piss" ? 100 : 10}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.bod_docker_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Docker host"))}"
}

# Provision the Docker EC2 instance via Ansible
module "bod_docker_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.bod_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.bod_docker.private_ip}",
    "bastion_host=${aws_instance.bod_bastion.public_ip}",
    "host_groups=bod_docker",
    "mongo_host=${aws_instance.cyhy_mongo.private_ip}"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
