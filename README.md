# 🏗️ Jour 5 / 10 — Terraform : CI/CD avec GitHub Actions

> **Série : 10 Days of Terraform** · Jour 5/10  
> Concepts : Plan sur PR · Apply sur merge · workflow_dispatch · Commentaire automatique · Artefacts

---

## 📁 Fichiers du projet

```
day-05-cicd/
│
├── main.tf                                    ← Resources Terraform
├── variables.tf                               ← Variables (dont commit_sha)
├── outputs.tf                                 ← Outputs de déploiement
├── Makefile                                   ← Commandes simplifiées
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml                 ← Plan automatique sur PR
│       ├── terraform-apply.yml                ← Apply sur merge dans main
│       └── terraform-destroy.yml              ← Destroy manuel uniquement
└── README.md
```

---

## 🧠 Le workflow CI/CD Terraform

```
Développeur ouvre une PR
    ↓
GitHub Actions lance terraform plan
    ↓
Le plan est commenté automatiquement sur la PR
    ↓
Code review + approbation
    ↓
Merge dans main
    ↓
GitHub Actions lance terraform apply
    ↓
Infrastructure mise à jour ✓
```

---

## 🚀 ÉTAPE 1 — Préparer les fichiers

```bash
mkdir -p jour5-terraform/.github/workflows
mkdir -p jour5-terraform/output
cd jour5-terraform/

# Copier les fichiers depuis le dépôt :
# main_j5.tf          → main.tf
# variables_j5.tf     → variables.tf
# outputs_j5.tf       → outputs.tf
# makefile_tf.txt     → Makefile
# terraform_plan.yml  → .github/workflows/terraform-plan.yml
# terraform_apply.yml → .github/workflows/terraform-apply.yml
# terraform_destroy.yml → .github/workflows/terraform-destroy.yml

cat > .gitignore << 'EOF'
.terraform/
.terraform.lock.hcl
terraform.tfstate*
output/
tfplan
EOF
```

---

## 🔑 ÉTAPE 2 — Tester localement avant de pousser

```bash
# Initialiser
terraform init

# Formater le code
terraform fmt -recursive

# Valider la syntaxe
terraform validate

# Plan avec commit_sha simulé
terraform plan -var="commit_sha=abc123def" -out=tfplan

# Apply
terraform apply tfplan

# Vérifier les outputs
terraform output -json
```

---

## 🔑 ÉTAPE 3 — Via le Makefile

```bash
# Plan (dev par défaut)
make plan

# Apply
make apply

# Plan sur staging
make plan ENV=staging
make apply ENV=staging

# Nettoyer
make clean
```

---

## 🔑 ÉTAPE 4 — Configurer GitHub

### Créer le dépôt et pousser

```bash
git init
git add .
git commit -m "feat: Terraform CI/CD jour 5"
git remote add origin https://github.com/ton-pseudo/10-days-terraform.git
git push -u origin main
```

### Configurer les secrets (si remote state S3)

```
GitHub → dépôt → Settings → Secrets → Actions → New secret

AWS_ACCESS_KEY_ID     = ton-access-key
AWS_SECRET_ACCESS_KEY = ton-secret-key
```

### Configurer l'environnement GitHub (protection prod)

```
GitHub → dépôt → Settings → Environments → New environment
Nom : production
→ Required reviewers : ajouter des reviewers
→ Prevent self-review : activer
```

---

## 🔑 ÉTAPE 5 — Workflow terraform-plan.yml expliqué

```yaml
on:
  pull_request:
    branches: [ main ]
    paths:
      - '**.tf'       # déclenché uniquement si des .tf changent
      - '**.tfvars'

steps:
  # Vérifier le format
  - run: terraform fmt -check -recursive

  # Générer le plan
  - run: terraform plan -var="commit_sha=${{ github.sha }}" -out=tfplan

  # Commenter la PR avec le résultat
  - uses: actions/github-script@v7
    with:
      script: |
        github.rest.issues.createComment({
          issue_number: context.issue.number,
          body: "Plan résultat : ..."
        })
```

---

## 🔑 ÉTAPE 6 — Workflow terraform-apply.yml expliqué

```yaml
on:
  push:
    branches: [ main ]    # déclenché sur merge dans main

jobs:
  terraform-apply:
    environment: production   # protection requiert approbation

    steps:
      - run: terraform apply
          -var="commit_sha=${{ github.sha }}"
          -var="version_app=${{ github.ref_name }}"
          -auto-approve

      # Uploader les fichiers générés comme artefacts
      - uses: actions/upload-artifact@v4
        with:
          name: terraform-outputs-${{ github.sha }}
          path: ./output/
          retention-days: 30
```

---

## 🔑 ÉTAPE 7 — Workflow destroy (manuel)

```yaml
on:
  workflow_dispatch:      # manuel uniquement — jamais automatique
    inputs:
      environnement:
        type: choice
        options: [dev, staging]
      confirmer:
        description: 'Taper CONFIRMER pour valider'

jobs:
  destroy:
    if: github.event.inputs.confirmer == 'CONFIRMER'
```

**Déclencher depuis GitHub :**
```
Actions → Terraform Destroy → Run workflow
→ Sélectionner l'environnement
→ Taper CONFIRMER
→ Run workflow
```

---

## 🚀 ÉTAPE 8 — Créer une PR pour tester le plan

```bash
# Créer une branche
git checkout -b feat/update-config

# Modifier une variable dans main.tf
# Ex : replicas de staging : 2 → 3

git add .
git commit -m "feat: augmenter replicas staging"
git push origin feat/update-config

# Ouvrir une PR sur GitHub
# → GitHub Actions lance terraform plan automatiquement
# → Le plan est commenté sur la PR
```

---

## 🚀 ÉTAPE 9 — Vérifier les artefacts après apply

```
GitHub → Actions → Dernier run "Terraform Apply"
→ Artifacts → terraform-outputs-abc123
→ Télécharger le zip
→ Contient tous les fichiers générés par Terraform
```

---

## 💡 Bonnes pratiques CI/CD Terraform

| Pratique | Pourquoi |
|----------|----------|
| Plan sur PR, Apply sur merge | Voir les changements avant de les appliquer |
| `continue-on-error: true` sur plan | Afficher le plan même s'il y a des erreurs |
| Commenter la PR avec le plan | Faciliter la code review |
| Environment protection sur prod | Approbation humaine avant apply prod |
| Destroy uniquement en manuel | Éviter les destructions accidentelles |
| `-no-color` en CI | Logs lisibles sans codes ANSI |
| Remote state partagé | Toute l'équipe voit le même state |



---

⭐ **Si ce projet t'aide, mets une étoile !**
