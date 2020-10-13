#!/bin/bash

echo "**************************"
echo "Installing worker node...."
echo "**************************"
echo


export http_proxy="http://web-proxy.in.softwaregrp.net:8080"
export https_proxy="http://web-proxy.in.softwaregrp.net:8080"

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
eepo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
             https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF


yum repolist

echo "***********************"
echo "Installintg Packages..."
echo "***********************"
echo
yum install kubeadm docker firewalld -y
echo

echo "*********************"
echo "Adding web proxy configuration..."
echo "*********************"

mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://web-proxy.in.softwaregrp.net:8080"
EOF
cat > /etc/systemd/system/docker.service.d/https-proxy.conf << EOF
[Service]
Environment="HTTPS_PROXY=http://web-proxy.in.softwaregrp.net:8080"
EOF

echo "********************"
echo "Starting Services..."
echo "********************"
systemctl  start docker && systemctl enable docker
systemctl  start kubelet && systemctl enable kubelet
echo

echo "*********************"
echo "Testing docker..."
echo "*********************"
echo
echo

docker pull hello-world
if [$? -ne 0 ]
then
   echo "Docker configuration failed"
   exit 1
else
   echo "Docker configuration was successful"
   echo
fi


echo "**************************"
echo "Allow Ports in Firewall..."
echo "**************************"
echo
firewall-cmd --permanent --add-port=10250/tcp --add-port=10255/tcp --add-port=30000-32767/tcp --add-port=6783/tcp
firewall-cmd  --reload

echo "*********************************************************************************"
echo "Worker node got initialize successfully"
echo
echo "Finally use 'kubeadm join' command to join this worker node in Kubernets Cluster"
echo
echo "*********************************************************************************"
