resource "aws_launch_template" "this" {
  # checkov:skip=CKV2_AWS_5: "SG attached via launch template, indirect attachment not detected"
  name_prefix   = "webserver-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name               = var.key_name
  vpc_security_group_ids = length(var.vpc_security_group_ids) > 0 ? var.vpc_security_group_ids : [aws_security_group.ec2[0].id]

  iam_instance_profile {
    name = var.iam_instance_profile_name != null ? var.iam_instance_profile_name : aws_iam_instance_profile.this[0].name
  }

    user_data = base64encode(<<-EOF
            #!/bin/bash
            set -euxo pipefail
            dnf -y update
            dnf -y install nginx
            systemctl enable nginx
            systemctl start nginx
            EOF
)


  monitoring {
    enabled = var.enable_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
  http_tokens = "required"
  http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}

