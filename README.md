
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

## Note
1. Rootless openvpn-as server requires "container_use_devices" sebool to be enabled
```bash
sudo setsebool -P container_use_devices on
```
2. Rootless openvpn-as server also needs [this](https://github.com/hasan4791/x-servers/blob/main/ansible/roles/setup-openvpnas/files/xs-openvpnas-policy.te) custom selinux module to allow "tun_tap_devices" for containers
3. Rootless Wireguard server requires MTU value to be updated in containers.conf for slirp4netns
```bash
echo "network_cmd_options=[\"mtu=1500\"]" | sudo tee -a /usr/share/containers/containers.conf
```
4. The default interface used in Rootless containers are "tap" interfaces and so any iptable rules that needs to be updated should point to this interface rather than the generic "eth"  type.

## Contributing

Contributions & Suggestions are always welcome :)
## Authors

- [@hasan4791](https://www.github.com/hasan4791)
## Feedback

If you have any feedback, please update in this [issue](https://github.com/hasan4791/x-servers/issues/4)
