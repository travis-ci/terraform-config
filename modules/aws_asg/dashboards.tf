resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.env}-${var.site}"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": true,
                "metrics": [
                    [ "Travis/${var.site}${var.env == "staging" ? "-staging" : ""}", "v1.travis.rabbitmq.consumers.builds.ec2.headroom", { "color": "#2ca02c", "period": 60, "stat": "Average" } ]
                ],
                "region": "us-east-1",
                "annotations": {
                    "horizontal": [
                        {
                            "color": "#ff7f0e",
                            "label": "Add ${var.worker_asg_scale_out_qty * 2} instances",
                            "value": ${var.worker_asg_scale_out_threshold + floor(var.worker_asg_scale_out_threshold/-2.0)}
                        },
                        {
                            "color": "#bcbd22",
                            "label": "Add ${var.worker_asg_scale_out_qty} instances",
                            "value": ${var.worker_asg_scale_out_threshold}
                        },
                        {
                            "label": "Remove ${var.worker_asg_scale_in_qty} instance",
                            "value": "${var.worker_asg_scale_in_threshold + 1}"
                        },
                        {
                            "label": "Remove ${var.worker_asg_scale_in_qty * 2} instances",
                            "value": "${var.worker_asg_scale_in_threshold * 1.5}"
                        },
                        {
                            "label": "Remove ${var.worker_asg_scale_in_qty * 3} instances",
                            "value": "${var.worker_asg_scale_in_threshold * 2}"
                        },
                        {
                            "color": "#d62728",
                            "label": "Add ${var.worker_asg_scale_out_qty * 3} instances",
                            "value": "${var.worker_asg_scale_out_threshold + floor(var.worker_asg_scale_out_threshold/-1.0)}"
                        }
                    ]
                },
                "title": "Headroom [${var.site}-${var.env}] (terraform)",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 9,
            "properties": {
                "view": "timeSeries",
                "stacked": true,
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${var.env}-${var.index}-workers-${var.site}", { "color": "#2ca02c", "period": 30, "stat": "Average" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "color": "#bcbd22", "period": 30 } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "period": 30 } ]
                ],
                "region": "us-east-1",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": ${var.worker_asg_min_size}
                    }
                }
            }
        }
    ]
}
 EOF
}
