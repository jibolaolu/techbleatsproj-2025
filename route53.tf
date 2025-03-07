# Create a CNAME record
resource "aws_route53_record" "sftp_cname" {
  zone_id = var.route53_zone_id
  name    = "${var.subdomain}.${var.domain_name}" # Full domain name (e.g., sftp.example.com)
  type    = "CNAME"
  ttl     = 300 # Time-to-live in seconds
  records = [aws_lb.tcs-alb.dns_name]

  depends_on = [aws_lb.tcs-alb]

}

resource "aws_route53_record" "api_a_record" {
  zone_id = var.route53_zone_id
  name    = "api.${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.tcs-alb.dns_name # ✅ Use the ALB DNS name
    zone_id                = aws_lb.tcs-alb.zone_id  # ✅ Ensure correct ALB Hosted Zone ID
    evaluate_target_health = true
  }
}
