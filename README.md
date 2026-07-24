# K3s Monitoring Stack

A lightweight, production-inspired monitoring stack for a K3s homelab built around the VictoriaMetrics ecosystem.

The stack provides:

- Metrics collection with **vmagent**
- Long-term metric storage with **VictoriaMetrics**
- Alert evaluation with **vmalert**
- Email notifications through **Alertmanager**
- Kubernetes metrics via **kube-state-metrics**

The manifests are rendered from templates using environment variable substitution, allowing the entire stack to be configured from a small set of variables.

---

# Architecture

```text
                Kubernetes Cluster
                        │
                        ▼
              kube-state-metrics
                        │
                        ▼
                    vmagent
                        │
                        ▼
               VictoriaMetrics
                        │
                ┌───────┴────────┐
                ▼                ▼
             vmalert        Grafana (optional)
                │
                ▼
           Alertmanager
                │
                ▼
             SMTP / Email
```

---

# Features

- Lightweight monitoring suitable for Raspberry Pi and other ARM devices
- VictoriaMetrics single-node storage
- Prometheus-compatible scraping
- Kubernetes health monitoring
- Storage monitoring
- Email alert notifications
- Template-based deployment
- Git-managed infrastructure
- Resource limits suitable for small clusters

---

# Repository Layout

```text
.
├── manifests/
│   ├── templates/
│   ├── monitoring/
│   └── ...
│
├── scripts/
│   ├── render.sh
│   └── validate.sh
│
├── .rendered/
│
├── Makefile
└── README.md
```

---

# Components

## VictoriaMetrics

Stores all scraped metrics.

Responsibilities:

- Time-series database
- Query endpoint
- Retention management

---

## vmagent

Responsible for scraping Kubernetes metrics and forwarding them to VictoriaMetrics.

Responsibilities:

- Service discovery
- Metric scraping
- Remote write
- Local buffering

---

## kube-state-metrics

Exposes Kubernetes object state.

Examples:

- Deployments
- Pods
- Nodes
- Jobs
- PVCs

---

## vmalert

Evaluates PromQL alert rules against VictoriaMetrics.

Responsibilities:

- Rule evaluation
- Alert generation
- Alert forwarding

---

## Alertmanager

Receives alerts from vmalert and sends notifications via email.

---

# Alert Rules

Current alerts include:

## Monitoring

- MetricsTargetDown

## Kubernetes

- NodeNotReady
- DeploymentUnavailable
- PodCrashLooping
- PodFailed
- JobFailed
- ContainerRestarted
- ContainerRestartingFrequently

## Storage

- PersistentVolumeClaimNearlyFull
- PersistentVolumeClaimCriticallyFull

---

# Rendering

Templates are rendered before deployment.

```bash
make render
```

The rendered manifests are written to:

```text
.rendered/
```

Only project-specific environment variables are substituted during rendering.

This intentionally preserves alert template variables such as:

```yaml
{{ $labels.namespace }}
{{ $labels.pod }}
{{ $labels.container }}
```

which are evaluated later by vmalert.

---

# Validation

Validate generated manifests before deployment.

```bash
make validate
```

---

# Deployment

Deploy the monitoring stack.

```bash
make install
```

Equivalent:

```bash
kubectl apply -f .rendered/
```

---

# Updating

After modifying templates:

```bash
make render
make validate
make install
```

Restart components if necessary:

```bash
kubectl rollout restart deployment/vmalert -n monitoring
```

---

# Resource Usage

Typical Raspberry Pi resource consumption:

| Component | Memory |
|-----------|--------:|
| VictoriaMetrics | ~170–200 MiB |
| vmagent | ~70–80 MiB |
| kube-state-metrics | ~15–20 MiB |
| Alertmanager | ~10–15 MiB |
| vmalert | <10 MiB |

---

# Email Notifications

Alerts are delivered through SMTP using Alertmanager.

Typical workflow:

```
Alert Rule
      │
      ▼
vmalert
      │
      ▼
Alertmanager
      │
      ▼
SMTP Server
      │
      ▼
Email Inbox
```

---

# Development Workflow

```bash
make render
make validate
make install
```

---

# Useful Commands

View monitoring pods:

```bash
kubectl get pods -n monitoring
```

Resource usage:

```bash
kubectl top pods -n monitoring
```

View logs:

```bash
kubectl logs deployment/vmalert -n monitoring

kubectl logs deployment/vmagent -n monitoring

kubectl logs statefulset/victoria-metrics -n monitoring
```

Restart vmalert:

```bash
kubectl rollout restart deployment/vmalert -n monitoring
```

Check alert rules:

```bash
kubectl -n monitoring exec deployment/vmalert -- \
wget -qO- http://127.0.0.1:8880/api/v1/rules
```

---

# Design Goals

- Simple
- Lightweight
- GitOps friendly
- ARM compatible
- Easy to understand
- Easy to extend
- Minimal operational overhead

---

# Notes

The rendering pipeline intentionally performs **restricted** environment variable substitution. This prevents shell expansion from modifying Prometheus/vmalert template expressions such as `{{ $labels.namespace }}`.

This safeguard ensures alert annotations are preserved correctly during manifest generation.

---
## Validation

Before deploying, render and validate the manifests:

```bash
make validate
```

The repository also runs the same validation automatically on every push and pull request using GitHub Actions.
```

# License

Apache-2.0 : License