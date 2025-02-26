# Create a CNAME record
resource "aws_route53_record" "sftp_cname" {
  zone_id = var.route53_zone_id
  name    = "${var.subdomain}.${var.domain_name}" # Full domain name (e.g., sftp.example.com)
  type    = "CNAME"
  ttl     = 300 # Time-to-live in seconds
  records = [aws_lb.tcs-alb.dns_name]

  depends_on = [aws_lb.tcs-alb]
}