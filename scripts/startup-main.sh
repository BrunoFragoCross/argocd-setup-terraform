echo "On the cmd inside the linux machine, you need to execute the line below before executing this script"
echo "sudo usermod -aG docker $USER && newgrp docker"

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl;
chmod +x kubectl;
sudo mv kubectl /usr/local/bin/;

wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64;
chmod +x minikube-linux-amd64;
sudo mv minikube-linux-amd64 /usr/local/bin/minikube;
minikube start --driver=docker;

kubectl create namespace argocd;
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml;
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64;
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd;
rm argocd-linux-amd64;

echo "To get your argoCD initial password, execute the following command:";
echo "argocd admin initial-password -n argocd";

echo "To expose the 8080 port to access argocd, use the following command:"
echo "kubectl port-forward --address 0.0.0.0 svc/argocd-server 8080:443 -n argocd";

echo "argoCD need a few seconds to start before the above commands work"

