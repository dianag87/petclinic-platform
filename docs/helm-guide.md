# Helm Chart Guide

**Last Updated:** 2026-06-09
**Purpose:** Documents the petclinic-service Helm chart structure, values hierarchy, and operational procedures for deploying and modifying services.

## Table of Contents

1. [Chart Structure](#chart-structure)
2. [Values Hierarchy](#values-hierarchy)
3. [Deploy a Service Manually](#deploy-a-service-manually)
4. [Add a New Service](#add-a-new-service)
5. [Change Resources, Replicas, or Env Vars](#change-resources-replicas-or-env-vars)
6. [ArgoCD Integration](#argocd-integration)
7. [Validation](#validation)

---

## Chart Structure

```
helm/petclinic-service/
├── Chart.yaml              # name: petclinic-service, version: 0.1.0
├── values.yaml             # defaults shared by all services
└── templates/
    ├── _helpers.tpl        # name, image, labels, selectorLabels helpers
    ├── deployment.yaml     # Deployment with probes, resources, init containers, secrets
    ├── service.yaml        # ClusterIP Service
    ├── configmap.yaml      # Non-secret config; SPRING_DATASOURCE_URL injected if needsDatabase=true
    ├── serviceaccount.yaml # ServiceAccount (one per service, for IRSA)
    ├── hpa.yaml            # HPA — only rendered when autoscaling.enabled=true
    └── pdb.yaml            # PDB — only rendered when podDisruptionBudget.enabled=true
```

All 8 services share this one chart. Per-service and per-environment differences live entirely in `helm-values/`.

---

## Values Hierarchy

Values are merged in order (later files win):

```
helm/petclinic-service/values.yaml    ← chart defaults
  + helm-values/{service}.yaml        ← service-specific (ports, env, init containers, probes)
  + helm-values/{env}.yaml            ← environment overrides (replicas, image env, RDS endpoint)
  + --set image.tag=${SHA}            ← CI injects commit SHA at deploy time
```

Key values controlled per layer:

| Value | Set in |
|-------|--------|
| `image.name` | per-service values |
| `image.tag` | per-service values (CI overrides) |
| `service.port` | per-service values |
| `component` | per-service values |
| `configMapData` | per-service values |
| `secretEnv` | per-service values |
| `initContainers` | per-service values |
| `needsDatabase` | per-service values |
| `autoscaling.*` | per-service values (enabled/disabled by env override) |
| `podDisruptionBudget.*` | per-service values (enabled/disabled by env override) |
| `replicaCount` | per-service values (overridden to 1 by dev.yaml) |
| `global.imageRegistry` | env values |
| `global.envName` | env values (dev / prod) |
| `global.rdsEndpoint` | env values |

The image reference is constructed in `_helpers.tpl` as:
```
{global.imageRegistry}/petclinic-{global.envName}/{image.name}:{image.tag}
```

---

## Deploy a Service Manually

```bash
# Deploy customers-service to dev
helm upgrade --install customers-service helm/petclinic-service/ \
  -n petclinic-dev \
  -f helm-values/customers-service.yaml \
  -f helm-values/dev.yaml \
  --set image.tag=${SHA}

# Deploy api-gateway to prod
helm upgrade --install api-gateway helm/petclinic-service/ \
  -n petclinic-prod \
  -f helm-values/api-gateway.yaml \
  -f helm-values/prod.yaml \
  --set image.tag=${SHA}
```

The release name (`customers-service`, `api-gateway`) becomes the resource name for the Deployment, Service, ConfigMap, and ServiceAccount.

---

## Add a New Service

1. Create `helm-values/{service-name}.yaml` with at minimum:
   ```yaml
   image:
     name: {service-name}
     tag: latest

   component: service   # or: server | gateway | admin

   service:
     port: {port}

   configMapData:
     SPRING_PROFILES_ACTIVE: docker
     CONFIG_SERVER_URL: http://config-server:8888

   initContainers:
     - name: wait-for-config-server
       image: busybox:1.36
       command: ['sh', '-c', 'until wget -qO- http://config-server:8888/actuator/health; do sleep 5; done']
       securityContext:
         allowPrivilegeEscalation: false
         capabilities:
           drop: ["ALL"]
         readOnlyRootFilesystem: true
       resources:
         requests:
           cpu: 10m
           memory: 32Mi
         limits:
           cpu: 50m
           memory: 64Mi

   replicaCount: 1   # prod default
   autoscaling:
     enabled: false
   podDisruptionBudget:
     enabled: false
   ```

2. If the service needs MySQL, add:
   ```yaml
   needsDatabase: true
   configMapData:
     SPRING_PROFILES_ACTIVE: docker,mysql
     EUREKA_CLIENT_SERVICEURL_DEFAULTZONE: http://discovery-server:8761/eureka/
   secretEnv:
     - name: SPRING_DATASOURCE_USERNAME
       secretName: rds-credentials
       secretKey: username
     - name: SPRING_DATASOURCE_PASSWORD
       secretName: rds-credentials
       secretKey: password
   ```

3. Validate: `bash scripts/validate-helm.sh`

4. Add ArgoCD Application CRDs in `k8s/argocd/applications/{dev,prod}/` — see [ArgoCD Integration](#argocd-integration).

---

## Change Resources, Replicas, or Env Vars

**Replicas (dev):** Dev replicas are always 1 — set by `helm-values/dev.yaml`. Do not change this.

**Replicas (prod):** Edit `replicaCount` in `helm-values/{service}.yaml`.

**HPA (prod):** Edit `autoscaling.*` in `helm-values/{service}.yaml`. HPA is disabled in dev by `dev.yaml`.

**Resources:** Edit `resources.requests` and `resources.limits` in `helm-values/{service}.yaml`.

**Env vars (non-secret):** Add to `configMapData` in `helm-values/{service}.yaml`. These become ConfigMap entries and are mounted via `envFrom`.

**Env vars (secret):** Add to `secretEnv` in `helm-values/{service}.yaml`. The referenced Secret must be managed by an ExternalSecret CR in `k8s/base/external-secrets/`.

**Probe paths:** Override `probes.readiness.path` and `probes.liveness.path` in the per-service values file (see `helm-values/config-server.yaml` for an example).

---

## ArgoCD Integration

ArgoCD deploys all services. Each service has one ArgoCD `Application` CRD per environment (16 total).

ArgoCD merges values the same way as manual Helm:
```yaml
source:
  helm:
    valueFiles:
      - ../../helm-values/{service}.yaml
      - ../../helm-values/{env}.yaml
```

CI commits updated `image.tag` to `helm-values/{service}.yaml`, ArgoCD detects the Git change and syncs:
- **Dev:** auto-sync (prune + self-heal enabled)
- **Prod:** manual sync required via ArgoCD UI or `argocd app sync {service}-prod`

Application CRDs are in `k8s/argocd/applications/{dev,prod}/`.

---

## Validation

Run before committing any chart or values changes:

```bash
bash scripts/validate-helm.sh
```

This runs `helm lint`, `helm template` (all 8 services × 2 envs), and `kubectl apply --dry-run=client` on every rendered manifest. All 17 checks must pass.
