
# X-Servers

Collection of my Personal Servers inspired from [linuxserver.io](https://www.linuxserver.io/)

## Supported Servers
1. Wireguard
2. Openvpn-AS

## Base container image
Ubuntu 22.04

## Host OS Supported
1. Any Fedora based distro
2. Official Raspberry pi OS 11

## Container Engine
Podman

## Container Modes
1. Root Containers
2. Rootless Containers

## Features

- Cron-job to auto update the target host & container images on every week
- Slack notification about the updates
- Root & Rootless container support for all servers
- Deployment of servers on Raspberry pi. Tested on Raspberry Pi 3B+ with Official os 11(Bullseye). Should work on other models as well.
## Deployment

To deploy this project on x86 hosts

1. Create ansible container image

```bash
 cd x-servers
 ./build.sh "amd64" "baseimage-ubuntu ."
 ./start.sh
 ansible-playbook -i <path_to_inventory_file>, setup-xsever.yml -u <non-root-user>
```
2. Create ansible inventory file with target host details
3. Copy & Update xserver configs. Refer [here](https://github.com/hasan4791/x-servers/blob/main/ansible/var_xservers.yml.template) for detailed information about configs
```bash
cp var_xserver.yml.template var_xserver.yml
vi var_xserver.yml
```
4. Run ansible playbook
```bash
ansible-playbook -i <path_to_inventory_file>, setup-xserver.yml -u <non-root-user>
```

Currently shell scripts are used for deployment which in future can be moved to kubernetes based resources like deploy/pod yaml.
## Contributing

Contributions & Suggestions are always welcome :)
## Authors

- [@hasan4791](https://www.github.com/hasan4791)
## Feedback

If you have any feedback, please update in this [issue](https://github.com/hasan4791/x-servers/issues/4)
