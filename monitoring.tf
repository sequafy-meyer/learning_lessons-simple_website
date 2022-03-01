resource "aws_cloudwatch_dashboard" "webpage" {
    dashboard_name = "My-Webpage"
    dashboard_body = file("templates/cf_dashboard.tpl")
    
}
