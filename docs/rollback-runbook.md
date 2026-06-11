# Rollback Runbook

**Last Updated:** 2026-06-10
**Purpose:** Procedures for rolling back a failed deployment. Three options are available in order of preference: GitOps revert, ArgoCD rollback, and emergency kubectl fallback.

## Table of Contents

1. [Option 1 — GitOps Revert (Preferred)](#option-1--gitops-revert-preferred)
2. [Option 2 — ArgoCD Rollback](#option-2--argocd-rollback)
3. [Option 3 — Emergency kubectl Fallback](#option-3--emergency-kubectl-fallback)
4. [Choosing the Right Option](#choosing-the-right-option)

---

### Procedure: GitOps Revert

**When:** A bad image tag was committed to `helm-values/` and ArgoCD synced it. Git is healthy. Preferred because it keeps Git as the source of truth.
**Who:** On-call engineer with push access to the platform repo
**Time:** 2–5 minutes

**Steps:**
1. Find the bad commit SHA:
   ```bash
   git log --oneline helm-values/
   ```
2. Revert it:
   ```bash
   git revert <bad-commit-sha> --no-edit
   git push
   ```
3. ArgoCD detects the revert commit and auto-syncs (dev) or queues for approval (prod).
4. For prod, trigger the sync manually:
   ```bash
   argocd app sync {service}-prod
   ```

**Verify:**
- `kubectl get pods -n petclinic-{env}` — pods running with the previous image
- `kubectl describe deployment {service} -n petclinic-{env}` — image tag matches the reverted SHA
- ArgoCD UI shows Healthy + Synced

**Rollback (if revert itself is wrong):**
- `git revert HEAD --no-edit && git push` to undo the revert

---

### Procedure: ArgoCD Rollback

**When:** Git is clean (revert not viable) but the running deployment is broken. Uses ArgoCD's sync history to redeploy a previous revision without touching Git.
**Who:** On-call engineer with ArgoCD access
**Time:** 2–3 minutes

**Steps:**
1. Port-forward ArgoCD (if no ingress):
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8443:443
   ```
2. Log in:
   ```bash
   argocd login localhost:8443
   ```
3. List sync history to find the last good revision:
   ```bash
   argocd app history {service}-{env}
   ```
4. Roll back to that revision:
   ```bash
   argocd app rollback {service}-{env} <revision-id>
   ```

**Verify:**
- `argocd app get {service}-{env}` — Status shows Healthy
- `kubectl get pods -n petclinic-{env}` — pods Running

**Rollback:**
- Re-sync to HEAD: `argocd app sync {service}-{env}` — returns to current Git state

---

### Procedure: Emergency kubectl Fallback

**When:** ArgoCD is unavailable and the pod is crash-looping. Last resort — bypasses GitOps, use only when the other two options are not possible.
**Who:** On-call engineer with kubectl cluster-admin access
**Time:** 1–2 minutes

**Steps:**
1. Undo the last rollout directly:
   ```bash
   kubectl rollout undo deployment/{service} -n petclinic-{env}
   ```
2. Watch rollout progress:
   ```bash
   kubectl rollout status deployment/{service} -n petclinic-{env}
   ```
3. After recovery, bring Git back in sync by reverting the bad tag commit (Option 1) so ArgoCD does not re-apply the broken image on the next sync.

**Verify:**
- `kubectl get pods -n petclinic-{env}` — pods Running
- `kubectl rollout history deployment/{service} -n petclinic-{env}` — confirms previous revision is active

**Rollback:**
- Redo the rollout: `kubectl rollout undo deployment/{service} -n petclinic-{env}` (undoes the undo)

---

## Choosing the Right Option

| Situation | Use |
|-----------|-----|
| Bad image tag committed to Git, ArgoCD synced it | Option 1 — GitOps revert |
| Git is healthy but deployment is broken | Option 2 — ArgoCD rollback |
| ArgoCD is down, pod is crash-looping | Option 3 — kubectl fallback |

Always follow up an Option 2 or Option 3 recovery with an Option 1 Git revert to keep Git as the source of truth.
