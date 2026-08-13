GitOps CI/CD Pipeline with GitHub Actions + ArgoCD
A fully automated GitOps deployment pipeline using GitHub Actions, Docker, Kubernetes (Minikube), and ArgoCD. This project demonstrates how to build, push, and deploy a Node.js application to a Kubernetes cluster using declarative GitOps principles.
Requirements
•	GitHub Actions
•	ArgoCD
o	Dev: expose via ngrok/inlets
o	Prod: deploy on EC2/EKS/GKE with TLS
•	Cloud Linux Instance (AWS EC2 Ubuntu t3.medium recommended)
•	Docker
•	Kubernetes (Minikube)
•	kubectl
1. Provision EC2 & Prepare Environment
SSH into EC2
bash
chmod 600 keypair.pem
ssh -i <keypair.pem> ubuntu@<PublicIP>
Update System
bash
sudo apt update && sudo apt upgrade -y
2. Install Docker
bash
sudo apt install docker.io -y
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
systemctl status docker
3. Install kubectl
bash
sudo snap install kubectl --classic
kubectl version –client

4. Install & Start Minikube
bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --driver=docker
kubectl get nodes
Enable ingress:
bash
minikube addons enable ingress
5. Configure GitHub Access
Create Personal Access Token
GitHub → Settings → Developer Settings → Tokens → Generate Token Scopes:
•	repo
•	workflow
•	admin:repo_hook
Save token securely.
Clone Repository
bash
git clone https://github.com/<your-username>/gitops-cicd-pipeline.git
6. GitHub Actions Workflow Setup
bash
mkdir -p .github/workflows
touch .github/workflows/argocd-actions.yml
7. Create DockerHub Repository
•	Repo name: githubactions-argocd-00
•	Visibility: Public
•	Create DockerHub PAT (R/W/D)
Add GitHub Secrets
Name	Value
DOCKERHUB_USERNAME	your username
DOCKERHUB_TOKEN	your token
   
8. Install ArgoCD
bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl get svc -n argocd
9. Expose ArgoCD
Add inbound rule for port 8080.
bash
kubectl port-forward --address 0.0.0.0 svc/argocd-server 8080:443 -n argocd
Get Initial Password
bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
Login: http://<PublicIP>:8080 User: admin Pass: <password>
10. Install ArgoCD CLI
bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/argocd
argocd version
11. Expose ArgoCD via NodePort
bash
kubectl edit svc argocd-server -n argocd
Set NodePort (30007 or 30008). Add inbound rule for NodePort.
Port-forward:
bash
kubectl port-forward --address 0.0.0.0 svc/argocd-server 30008:443 -n argocd
12. Add ArgoCD Secrets to GitHub
Name	Value
ARGOCD_SERVER	PublicIP:30008
ARGOCD_USERNAME	admin
ARGOCD_PASSWORD	<password>
13. Connect Repo in ArgoCD
ArgoCD UI → Settings → Repositories → Connect
•	Method: HTTPS
•	Type: git
•	Repo URL: your GitHub repo
•	Project: default
14. Create ArgoCD Application
ArgoCD UI → Applications → New App
•	Name: argocd-github-actions
•	Repo: your repo
•	Path: manifest
•	Sync Policy: Automatic
•	Prune + Self Heal: Enabled
•	Destination: kubernetes.default.svc
•	Namespace: argocd
15. Deploy & Sync
Update your Deployment manifest with the latest Docker image tag.
ArgoCD will auto-sync.
Inspect:
bash
kubectl get deploy -n argocd
kubectl get svc -n argocd
16. Run Node App
Install npm:
bash
sudo apt install npm -y
sudo npm install
node app.js
Visit: http://<PublicIP>:3000/hello
17. Run App via ArgoCD Deployment
bash
kubectl port-forward --address 0.0.0.0 svc/myapp-service 8080:80 -n argocd
Visit: http://<PublicIP>:8080/hello
18. Cleanup
bash
kubectl delete ns argocd
minikube stop
minikube delete --all
Terminate EC2 instance.

