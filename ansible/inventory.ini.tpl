[app_servers]
${APP_SERVER_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/counter_deploy_key ansible_ssh_common_args="-o StrictHostKeyChecking=no"
