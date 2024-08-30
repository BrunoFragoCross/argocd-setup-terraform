sudo dnf update -y;
sudo dnf install docker -y;
sudo usermod -aG docker ec2-user;

sudo systemctl start docker;
sudo systemctl enable docker;

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl;
chmod +x kubectl;
sudo mv kubectl /usr/local/bin/;

wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64;
chmod +x minikube-linux-amd64;
sudo mv minikube-linux-amd64 /usr/local/bin/minikube;
sudo -u ec2-user minikube start --driver=docker;

sudo -u ec2-user kubectl create namespace argocd;
sudo -u ec2-user kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml;
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64;
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd;
rm argocd-linux-amd64;

echo "To get your argoCD initial password, execute the following command inside the vm:";
echo "argocd admin initial-password -n argocd";

echo "To expose the 8080 port to access argocd, use the following command:";
echo "kubectl port-forward --address 0.0.0.0 svc/argocd-server 8080:443 -n argocd";

