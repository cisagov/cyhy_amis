data "aws_ami" "nmap" {
  filter {
    name = "name"
    values = [
      "cyhy-nmap-hvm-*-x86_64-ebs"
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

resource "aws_instance" "cyhy_nmap" {
  ami = "${data.aws_ami.nmap.id}"
  instance_type = "${local.production_workspace ? "t2.micro" : "t2.micro"}"
  count = "${local.nmap_instance_count}"

  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  # We may want to spread instances across all availability zones, however
  # this will also require creating a scanner subnet in each availability zone
  # availability_zone = "${element(data.aws_availability_zones.all.names, count.index)}"

  subnet_id = "${aws_subnet.cyhy_scanner_subnet.id}"
  private_ip = "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, count.index + local.first_port_scanner)}"

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 16 : 8}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_and_cyhy_runner_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", format("CyHy Nmap - portscan%d", count.index+1), "Publish Egress", "True"))}"
  volume_tags = "${merge(var.tags, map("Name", format("CyHy Nmap - portscan%d", count.index+1)))}"
}

# Note that the EBS volume contains production data. Therefore we need
# these resources to be immortal in the "production" workspace, and so
# I am using the prevent_destroy lifecycle element to disallow the
# destruction of it via terraform in that case.
#
# I'd like to use "${terraform.workspace == "production" ? true :
# false}", so the prevent_destroy only applies to the production
# workspace, but it appears that interpolations are not supported
# inside of the lifecycle block
# (https://github.com/hashicorp/terraform/issues/3116).
resource "aws_ebs_volume" "nmap_cyhy_runner_data" {
  count = "${local.nmap_instance_count}"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  # availability_zone = "${element(data.aws_availability_zones.all.names, count.index)}"
  type = "gp2"
  size = "${local.production_workspace ? 2 : 1}"
  encrypted = true

  tags = "${merge(var.tags, map("Name", format("CyHy Nmap - portscan%d", count.index+1)))}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "nmap_cyhy_runner_data_attachment" {
  count = "${local.nmap_instance_count}"
  device_name = "${var.cyhy_runner_disk}"
  volume_id = "${aws_ebs_volume.nmap_cyhy_runner_data.*.id[count.index]}"
  instance_id = "${aws_instance.cyhy_nmap.*.id[count.index]}"

  # Terraform attempts to destroy the volume attachment before it attempts to
  # destroy the EC2 instance it is attached to.  EC2 does not like that and it
  # results in the failed destruction of the volume attachment.  To get around
  # this, we explicitly terminate the cyhy_nmap instance via the AWS CLI
  # in a destroy provisioner; this gracefully shuts down the instance and
  # allows terraform to successfully destroy the volume attachments.
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${aws_instance.cyhy_nmap.id}"
    on_failure = "continue"
  }

  # Wait until cyhy_nmap instance is terminated before continuing on
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${aws_instance.cyhy_nmap.id}"
  }

  skip_destroy = true
  depends_on = ["aws_ebs_volume.nmap_cyhy_runner_data"]
}

# load in the dynamically created provisioner modules
module "dyn_nmap" {
  source = "./dyn_nmap"
  bastion_public_ip = "${aws_instance.cyhy_bastion.public_ip}"
  nmap_private_ips = "${aws_instance.cyhy_nmap.*.private_ip}"
  remote_ssh_user = "${var.remote_ssh_user}"
}

module "cyhy_nmap_ansible_provisioner_24" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[24]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_25" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[25]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_26" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[26]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_27" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[27]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_28" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[28]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_29" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[29]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_30" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[30]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_31" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[31]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_32" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[32]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_33" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[33]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_34" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[34]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_35" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[35]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_36" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[36]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_37" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[37]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_38" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[38]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_39" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[39]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_40" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[40]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_41" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[41]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_42" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[42]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_43" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[43]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_44" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[44]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_45" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[45]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_46" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[46]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_47" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[47]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_48" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[48]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_49" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[49]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_50" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[50]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_51" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[51]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_52" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[52]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_53" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[53]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_54" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[54]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_55" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[55]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_56" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[56]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_57" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[57]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_58" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[58]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_59" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[59]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_60" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[60]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_61" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[61]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_62" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[62]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

module "cyhy_nmap_ansible_provisioner_63" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.*.private_ip[63]}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
