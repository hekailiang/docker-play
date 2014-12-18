#!/bin/bash
##Docker will forward port 80 to, say, port 49153 on the VM, and VirtualBox will forward port 49153 from the VM to localhost.

for i in {49000..49900}; do
    VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port$i,tcp,,$i,,$i";
    VBoxManage modifyvm "boot2docker-vm" --natpf1 "udp-port$i,udp,,$i,,$i";
done
