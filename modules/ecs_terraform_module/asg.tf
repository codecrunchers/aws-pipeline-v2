resource "aws_autoscaling_group" "ecs_asgrp" {
  name                      = "${var.environment}-${var.name}-ecs-asgrp"
  vpc_zone_identifier       = ["${var.private_subnet_ids}"]
  min_size                  = "${var.ecs_params["min_instances"]}"
  max_size                  = "${var.ecs_params["max_instances"]}"
  desired_capacity          = "${var.ecs_params["desired_instances"]}"
  launch_configuration      = "${aws_launch_configuration.ecs_launch_config.id}"
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity       = "1Minute"
  health_check_grace_period = 1000
  target_group_arns         = ["${aws_alb_target_group.alb_target_groups.*.arn}"]

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Stream"
    value               = "Stream Tag"
    propagate_at_launch = true
  }

  tag {
    key                 = "ServerRole"
    value               = "ECS"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix          = "${var.environment}-${var.name}-ecs-launch_configuration"
  security_groups      = ["${aws_security_group.ecs_instance_sg.id}"]
  image_id             = "${lookup(var.ecs_amis, var.aws_region)}"
  key_name             = "${var.ssh_key}"
  instance_type        = "${var.ecs_params["instance_type"]}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.id}"
  enable_monitoring    = true

  #  user_data                   = "#!/bin/bash\necho ECS_CLUSTER='${aws_ecs_cluster.ecs.id}' > /etc/ecs/ecs.config"
  user_data = "${data.template_file.user_data.rendered}"

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user-data-ecsami.instance")}"

  vars {
    efs_url      = "${var.efs_mount_dns}"
    p9_env       = "${var.environment}"
    cluster_name = "${var.cluster_name}"
    consul_ip    = "${var.consul_private_ip}"
  }
}

#data "template_file" "instance_profile" {
#  template = "${file("${path.module}/templates/instance-profile-policy.json")}"
#
#  vars {
#    app_log_group_arn       = "${var.cloudwatch_log_handle}"
#    ecs_agent_log_group_arn = "${var.cloudwatch_log_handle}"
#  }
#}

