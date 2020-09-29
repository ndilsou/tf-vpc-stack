output "vpc" {
  value = aws_vpc.main.id
}

output "nat_public_ips" {
  value = {
    for eip in aws_eip.ngw_eip :
    eip.id => eip.public_ip
  }
}

output "public_subnets" {
  value = {
    for subnet in aws_subnet.public :
    subnet.id => subnet.cidr_block
  }
}

output "private_subnets" {
  value = {
    for subnet in aws_subnet.private :
    subnet.id => subnet.cidr_block
  }
}
