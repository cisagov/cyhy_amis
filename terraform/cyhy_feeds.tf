# The feeds EC2 instance
data "aws_ami" "cyhy_feeds" {
  filter {
    name = "name"
    values = [
      "cyhy-feeds-hvm-*-x86_64-ebs"
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
 resource "aws_instance" "cyhy_feeds" {
  ami = "${data.aws_ami.cyhy_feeds.id}"
  instance_type = "${local.production_workspace ? "r5.large" : "t2.micro"}"
  ebs_optimized = "${local.production_workspace}"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
   # This is the private subnet
  subnet_id = "${aws_subnet.cyhy_private_subnet.id}"
  associate_public_ip_address = false
   root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 200 : 8}"
    delete_on_termination = true
  }
   vpc_security_group_ids = [
    "${aws_security_group.cyhy_private_sg.id}"
  ]
   user_data = "${data.template_cloudinit_config.cyhy_ssh_cloud_init_tasks.rendered}"
   tags = "${merge(var.tags, map("Name", "CyHy Feeds"))}"
   # When the feeds starts up, it looks for a database,
  # so make this instance dependent on cyhy_mongo
  depends_on = ["aws_instance.cyhy_feeds"]
}
 # Provision the feeds EC2 instance via Ansible
module "cyhy_feeds_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"
   arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_feeds.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_feeds"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
