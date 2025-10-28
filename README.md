# Go Web Application with K8S & GitLab CI/CD

A simple Go web application that serves a "Hello from Go!" message. This project includes Dockerization, Kubernetes deployment manifests for `dev` and `prod` environments, and a GitLab CI/CD pipeline with automated testing and deployment.

## Project Structure

```
k8s-project
├── main.go
├── Dockerfile
├── test.sh
├── gitlab-ci.yml
├── .gitignore
├── .dockerignore
├── test/
│   └── gitlab-test.yml
├── k8s/
│   ├── dev/
│   │   ├── ConfigMap.yaml
│   │   ├── Service.yaml
│   │   ├── Deployment.yaml
│   │   └── Ingress.yaml
│   └── prod/
│       ├── ConfigMap.yaml
│       ├── Service.yaml
│       ├── Deployment.yaml
│       └── Ingress.yaml
└── README.md
```

---

## Prerequisites

Before you begin, ensure you have the following:

- A **GitLab** account and project repository.
- Access to a **private Docker registry** (e.g., Nexus, Harbor) at `docker.registry.local`.
- A **Kubernetes cluster** with `kubectl` configured.
- **GitLab CI/CD variables** set:
  - `NEXUS_USER`: Username for Docker registry.
  - `NEXUS_PASSWORD`: Password for Docker registry.
  - `KUBE_CONFIG`: Base64-encoded kubeconfig file for cluster access.

> You can set these variables in **GitLab > Settings > CI/CD > Variables**.

# Configure Containerd to Use Private Registry

Since your images are pushed to a private registry (`docker.registry.local`), you must configure `containerd` on all Kubernetes worker nodes to trust this registry.

### Step 1: Edit containerd config

On each worker node, edit `/etc/containerd/config.toml`:

```bash
sudo vim /etc/containerd/config.toml
```

```toml
[plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"

```
Then create this directory

```bash
mkdir /etc/containerd/certs.d

```
In there you will always need a new directory for every registry that you want to mirror. Examples would be `registry.k8s.io` or `docker.io`.

```bash
mkdir /etc/containerd/certs.d/registry.k8s.io
mkdir /etc/containerd/certs.d/docker.io

```
In this directory you need to create a `hosts.toml` with the following content

```toml
[host."http://docker.registry.local"]
	capabilities = ["pull", "resolve"]
```

```bash
kubectl create secret docker-registry regcred \
  --docker-server=docker.registry.local \
  --docker-username=$NEXUS_USER \
  --docker-password=$NEXUS_PASSWORD \
  --docker-email=your-email@example.com \
  -n dev

kubectl create secret docker-registry regcred \
  --docker-server=docker.registry.local \
  --docker-username=$NEXUS_USER \
  --docker-password=$NEXUS_PASSWORD \
  --docker-email=your-email@example.com \
  -n prod
```
Add `imagePullSecrets` to Your Deployments:

Update your `k8s/dev/Deployment.yaml` and `k8s/prod/Deployment.yaml` files to include:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: regcred
```

Step 2: Restart containerd

```bash
sudo systemctl restart containerd
```
---

## How to Run Tests Locally

1. Make sure you have Go installed (`go version`).
2. Run the test script:

```bash
chmod +x test.sh
./test.sh
```

This will start the Go server locally on port 80 and verify it returns `"Hello from Go!"`.

---

## Deploy to Kubernetes

### 1. Manual Deployment (for testing)

#### For Development:

```bash
kubectl apply -f k8s/dev/
```

#### For Production:

```bash
kubectl apply -f k8s/prod/
```

> Ensure namespaces `dev` and `prod` exist:

```bash
kubectl create namespace dev
kubectl create namespace prod
```

---

## GitLab CI/CD Pipeline

The pipeline has 5 stages:

| Stage        | Description                                   | Trigger Condition     |
|--------------|-----------------------------------------------|------------------------|
| `build_dev`  | Builds and pushes image tagged with `$CI_PIPELINE_ID` | On `dev` branch        |
| `test`       | Runs unit/integration tests via `test/gitlab-test.yml` | On `dev`, `master`, `tags` |
| `deploy_dev` | Deploys to `dev` namespace                    | On `dev` branch        |
| `build_prod` | Builds and pushes image tagged with `$CI_COMMIT_TAG` | On `master` or `tags`  |
| `deploy_prod`| Deploys to `prod` namespace (manual trigger)  | On `tags` only         |

### Automatic Deployment

- Every commit to the `dev` branch triggers:
  - Build → Test → Deploy to `dev` namespace.

### Manual Deployment to Production

1. Create a Git tag (e.g., `v1.0.0`) and push it:

```bash
git tag v1.0.0
git push origin v1.0.0
```

2. In GitLab, go to **CI/CD > Pipelines**, find the pipeline for the tag, and manually trigger the `deploy_prod` job.

---

## Notes

- All Docker images are pushed to the private registry: `docker.registry.local/go-k8s-project:<tag>`.
- The `test` stage is modular and defined in `test/gitlab-test.yml` (as requested).
