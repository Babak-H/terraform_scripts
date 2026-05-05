# create the cloudwatch metric alarm that will send the logs to the SNS topic
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name = "EC2-High-CPU-(${aws_instance.my_server.id})"
  # the alarm is related to EC2 instances
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  # CloudWatch CPU alarms are scoped to one EC2 instance through the InstanceId dimension
  dimensions = {
    InstanceId = aws_instance.my_server.id
  }

   # it can be >  <  =  >=  <=
  comparison_operator = "GreaterThanOrEqualToThreshold"
  # the number of periods over which data is compared to the specified threshold
  evaluation_periods  = 1
  # The period in seconds over which the specified statistic is applied. Valid values are 10, 30, or any multiple of 60
  period              = 300
  # in the average of 300 seconds evaluate the cpu usage
  statistic           = "Average"
  # when the cpu usage is >= 80%
  threshold           = 80
  alarm_description   = "Monitors average EC2 CPU utilization over 5 minutes"

  # Do not publish notifications when the alarm has insufficient data (do nothing in this case)
  insufficient_data_actions = []

  # Publish a notification when the alarm returns to OK ( <80% CPU)
  ok_actions = [aws_sns_topic.alarms.arn]

  # Publish a notification when CPU utilization is greater than or equal to 80%
  alarm_actions = [aws_sns_topic.alarms.arn]
}
