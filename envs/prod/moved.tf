# Reconciles state addresses from the pre-module flat root layout
# (VPC resources originally applied directly at root, before the
# modules/network + envs/<env> restructure) into their new module
# addresses. Safe to remove once confidence is high that no other
# state/branch still references the old addresses.

moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_subnet.private
  to   = module.network.aws_subnet.private
}

moved {
  from = aws_subnet.database
  to   = module.network.aws_subnet.database
}

moved {
  from = aws_eip.nat
  to   = module.network.aws_eip.nat
}

moved {
  from = aws_nat_gateway.main
  to   = module.network.aws_nat_gateway.main
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table.private
  to   = module.network.aws_route_table.private
}

moved {
  from = aws_route_table.database
  to   = module.network.aws_route_table.database
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_route_table_association.private
  to   = module.network.aws_route_table_association.private
}

moved {
  from = aws_route_table_association.database
  to   = module.network.aws_route_table_association.database
}
