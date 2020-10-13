#!/bin/bash


echo
echo "**********************************"
echo "Master Installation is running...."
echo "**********************************"
echo

export http_proxy=http://web-proxy.in.softwaregrp.net:8080
export https_proxy=http://web-proxy.in.softwaregrp.net:8080

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

echo "************************"
echo "Installintg Packages..."
echo "************************"

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

echo "*********************"
echo "Starting Services..."
echo "*********************"
echo

systemctl  start docker && systemctl enable docker
systemctl  start kubelet && systemctl enable kubelet

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
firewall-cmd --permanent --add-port=6443/tcp --add-port=2379-2380/tcp --add-port=10250/tcp --add-port=10251/tcp --add-port=10252/tcp --add-port=10255/tcp
firewall-cmd --reload

echo "*************************************"
echo "Kube Master is getting Initialize...."
echo "*************************************"
echo
echo
kubeadm init


echo "**********************************"
echo "Running Post Installation Tasks..."
echo "**********************************"
echo
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

echo
echo "************************************"
echo "Cheking the status of Nodes and PODs"
echo "************************************"
echo
echo "It may take some time..."
echo
sleep 30s
echo "***********"
echo "Node Status"
echo "***********"

kubectl get nodes
echo
echo
echo "***********"
echo "PODS Status"
echo "***********"
echo
echo "Press ctrl+c to get exit"
echo
kubectl  get  pods  -o wide --all-namespaces
