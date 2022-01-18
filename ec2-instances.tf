provider "aws" {

} 

   
resource "aws_security_group" "web_server"{
  name        = "SG for web server"


  ingress {
    
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  tags = {
         Name = "my SG"
         Owner = "Anton"
         Project = "ITAcademy demo1"
     }
  }



#INSTANCES 
#creating instances
resource "aws_instance" "web_server" {
     count = 2
     ami = "ami-0d527b8c289b4af7f"
     instance_type = "t3.micro"
     vpc_security_group_ids = [aws_security_group.web_server.id]
         tags = {
         Name = "aws instance"
         Owner = "Anton"
         Project = "ITAcademy demo1"
     }
     
     
     user_data = <<EOF
#!/bin/bash
apt -y update      
apt -y install apache2 
apt -y install wget      
wget -qO- ipinfo.io/ip > /var/www/html/index.html
echo "<h2></h2><br>Build By Terraform!" >> /var/www/html/index.html 
sudo service apache2 start 
apachectl configtest  
EOF 
}



#LOAD BALANCER
resource "aws_alb" "alb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["subnet-05e84fe77e6bc29fe"]

  enable_deletion_protection = false

  tags = {
    Environment = "demo_alb"
  }
}
resource "aws_alb_target_group" "web_server" {
  count = 1
  name        = "tf-example-lb-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = "vpc-080c02c14fb486457"
 
}
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_alb_target_group.web_server[0].id
    type             = "forward"
  }
}
resource "aws_lb_target_group_attachment" "web_server" {
  count = length(aws_instance.web_server)
  target_group_arn = aws_alb_target_group.web_server[0].id
  target_id        = aws_instance.web_server[count.index].id 
  port             = 80
  
}
output "alb_hostname" {
  value = aws_alb.alb.dns_name
}