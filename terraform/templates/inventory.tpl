[all:vars]
ansible_user=${ssh_user}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[load_balancer]
lb-01 ansible_host=${lb_ip}

[web_servers]
%{ for idx, ip in web_ips ~}
web-${format("%02d", idx + 1)} ansible_host=${ip}
%{ endfor ~}

[app_servers]
%{ for idx, ip in app_ips ~}
app-${format("%02d", idx + 1)} ansible_host=${ip}
%{ endfor ~}

[db_servers]
db-master ansible_host=${db_master_ip} role=master
db-slave ansible_host=${db_slave_ip} role=slave

[db_master]
db-master ansible_host=${db_master_ip}

[db_slave]
db-slave ansible_host=${db_slave_ip}
