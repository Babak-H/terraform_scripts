# create the cloudwatch metric alarm that will send the logs to the SNS topic
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name = "EC2 High CPU (${aws_instance.my_server.id})"
  # the alarm is related to EC2 instances
  namespace = "AWS/EC2"
  metric_name = "CPUUtilization"
  #  you have to create a separate alarm for each EC2 instance
  dimensions = {
    InstanceId = aws_instance.my_server.id
  }
  # it can be >  <  =  >=  <=
  comparison_operator = "GreaterThanOrEqualToThreshold"
  # he number of periods over which data is compared to the specified threshold
  evaluation_periods = "1"
  #  The period in seconds over which the specified statistic is applied. Valid values are 10, 30, or any multiple of 60
  period = "300"
  # in the averge of 300 seconds evaluate the cpu usage
  statistic = "Average"
  # when the cpu usage is >= 80%
  threshold = "80"
  alarm_description = "this metric monitors CPU utilization for an instance"
  # do nothing when we have no data
  insufficient_data_actions = []
  
  # send the alarm when the CPUUtilization <80
  ok_actions = [aws_sns_topic.alarms.arn]
  # send the alarm when the CPUUtilization >=80
  alarm_actions = [aws_sns_topic.alarms.arn]
}