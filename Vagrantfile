Vagrant.configure("2") do |config|
config.vm.box = "kalilinux/rolling"
config.vm.hostname = "cyrax"

# config.vm.network "private_network", type: "dhcp"

# Timeouts aumentados para Llama AI
config.vm.boot_timeout = 600
config.vm.graceful_halt_timeout = 60

config.vm.synced_folder ".", "/vagrant", disabled: false

config.vm.provider "virtualbox" do |vb|
vb.name = "cyrax"
vb.memory = "8192"  # 8GB para Llama AI
vb.cpus = 4         # 4 CPUs para processamento IA
vb.gui = true
vb.customize ["modifyvm", :id, "--audio", "none"]
vb.customize ["modifyvm", :id, "--clipboard", "disabled"]
vb.customize ["modifyvm", :id, "--draganddrop", "disabled"]
vb.customize ["modifyvm", :id, "--usb", "off"]
vb.customize ["modifyvm", :id, "--vrde", "off"]
vb.customize ["modifyvm", :id, "--macaddress1", "auto"]
vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
# Otimizações para IA
vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
vb.customize ["modifyvm", :id, "--largepages", "on"]
vb.customize ["modifyvm", :id, "--ioapic", "on"]
vb.customize ["modifyvm", :id, "--pae", "on"]
vb.customize ["modifyvm", :id, "--vram", "256"]
end

config.vm.provision "shell", path: "provision.sh"

config.vm.provision "shell", run: "always", inline: <<-SHELL
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -w net.ipv6.conf.eth0.disable_ipv6=1 2>/dev/null || true
sysctl -w net.ipv6.conf.eth1.disable_ipv6=1 2>/dev/null || true
grep -q 'disable_ipv6' /etc/sysctl.conf || echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf

rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup
ln -sf /etc/machine-id /var/lib/dbus/machine-id

chattr -i /etc/resolv.conf 2>/dev/null || true
cat > /etc/resolv.conf <<EOFDNS
nameserver 127.0.0.1
nameserver 1.1.1.1
EOFDNS
chattr +i /etc/resolv.conf

rm -f /home/*/.bash_history /home/*/.zsh_history /root/.bash_history

setxkbmap -model abnt2 -layout br -variant abnt2 2>/dev/null || true
loadkeys br-abnt2 2>/dev/null || true
SHELL
end