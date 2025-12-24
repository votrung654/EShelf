# Ansible Playbooks cho eShelf K3s Cluster

## Yêu cầu

```bash
# Cài đặt Ansible
pip install ansible

# Cài đặt các collections cần thiết
ansible-galaxy collection install -r requirements.yml
```

## Thiết lập

### 1. Cập nhật Inventory

Sửa `inventory/dev.ini` (hoặc staging/prod) và thay thế:
- `CHANGE_ME_MASTER_IP` bằng IP của master node
- `CHANGE_ME_WORKER1_IP` bằng IP của worker 1
- `CHANGE_ME_WORKER2_IP` bằng IP của worker 2

### 2. Thiết lập SSH Key

```bash
# Copy SSH key đến các nodes
ssh-copy-id -i ~/.ssh/id_rsa.pub ec2-user@<MASTER_IP>
ssh-copy-id -i ~/.ssh/id_rsa.pub ec2-user@<WORKER1_IP>
ssh-copy-id -i ~/.ssh/id_rsa.pub ec2-user@<WORKER2_IP>
```

### 3. Chạy Playbooks

```bash
# Thiết lập K3s cluster
ansible-playbook -i inventory/dev.ini playbooks/setup-cluster.yml

# Thiết lập tools (Helm, kustomize, yq)
ansible-playbook -i inventory/dev.ini playbooks/setup-tools.yml
```

### 4. Lấy Kubeconfig

```bash
# Copy kubeconfig từ master
scp ec2-user@<MASTER_IP>:~/.kube/config ~/.kube/config

# Cập nhật server URL nếu cần
sed -i 's/127.0.0.1/<MASTER_IP>/g' ~/.kube/config

# Kiểm tra kết nối
kubectl get nodes
```

## Playbooks

- `setup-cluster.yml` - Thiết lập K3s master và workers
- `k3s-master.yml` - Cài đặt K3s master node
- `k3s-worker.yml` - Cài đặt K3s worker nodes
- `setup-tools.yml` - Cài đặt Helm, kustomize, yq
