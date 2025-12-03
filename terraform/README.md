# RAG Bot - Minimal Azure Sandbox

These Terraform files provision the lightest-possible Azure Container Apps setup so you can iterate quickly without wiring up registries, identities, or Key Vault just yet.

## Prerequisites

1. **Azure CLI** logged into the subscription you want to use:
  ```bash
  az login
  az account set --subscription <subscription-id>
  ```
2. **Terraform 1.0+**:
  ```bash
  brew install terraform
  ```
3. **Container image published to a registry.** Public images work out of the box. For private GHCR images, supply a username + PAT in `terraform.tfvars` (details below).

## What gets created

- Resource group for the sandbox
- Log Analytics workspace (required by Container Apps)
- Container Apps environment
- Single Container App with optional environment variables + secret

That's it—no Key Vault, no managed identity, no Azure Files.

## Quick start

1. Copy and edit the variable file:
  ```bash
  cd terraform
  cp terraform.tfvars.example terraform.tfvars
  ```
  Update:
  - `container_image` to the full reference of your published image
  - `container_port` if your app doesn't listen on 8000
  - `openai_api_key` only when you actually need the secret
  - any extra `environment_variables`
  - If the image is private, add `registry_server`, `registry_username`, and `registry_password` (PAT)

2. Deploy:
  ```bash
  terraform init
  terraform plan
  terraform apply
  ```

3. Grab the URL:
  ```bash
  terraform output container_app_url
  ```

Open the printed URL in your browser—you're live.

## Updating the app image

Just push a new tag to the registry you referenced in `container_image`, then run:

```bash
terraform apply -var="container_image=<new full image ref>"
```

Because the config ignores `template[0].container[0].image` drift, you can also use `az containerapp revision restart --name <app> --resource-group <rg>` to pull the latest tag without touching Terraform.

## Logs & troubleshooting

```bash
az containerapp logs show \
  --name $(terraform output -raw container_app_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --follow
```

- **Image pull errors**: confirm the registry is public or that you've provided credentials (`registry_*` vars). GHCR tokens need `read:packages`.
- **Container crash loops**: inspect logs above; adjust env vars in `terraform.tfvars` and re-apply.
- **Secret missing**: leave `openai_api_key` blank if you don't need it; when set, Terraform injects it as the `OPENAI_API_KEY` secret automatically.

## Using GHCR with private images

1. Build a linux/amd64 image with Docker Buildx (required for Azure Container Apps):
  ```bash
  # create a builder once (skip if already created)
  docker buildx create --name ragbot-builder --use

  # build and push an amd64 image straight to GHCR
  docker buildx build \
    --platform linux/amd64 \
    -t ghcr.io/<owner>/rag-bot:latest \
    .. \
    --push
  ```
  _Need both ARM64 + AMD64?_ Use `--platform linux/amd64,linux/arm64` to publish a multi-arch manifest.
2. Create a GitHub Personal Access Token (classic or fine-grained) with `read:packages` and `write:packages`. Approve org access if the repo lives under an organization.
3. Log into GHCR (Docker image references must be lowercase even if your GitHub repo uses uppercase):
  ```bash
  export GHCR_PAT=ghp_yourRealToken
  echo "$GHCR_PAT" | docker login ghcr.io -u <your-github-username> --password-stdin
  ```
4. (Optional) If you prefer a separate push step, you can still `docker tag` + `docker push`; just ensure you pass `--platform linux/amd64` (or set `DOCKER_DEFAULT_PLATFORM`) when building.
5. Wire credentials into Terraform (`terraform.tfvars`):
  ```hcl
  container_image   = "ghcr.io/<owner>/rag-bot:latest"
  registry_server   = "ghcr.io"
  registry_username = "<your-github-username>"
  registry_password = "ghp_yourRealToken"
  ```
  The `registry_password` stays in your ignored `terraform.tfvars`; Terraform copies it into an Azure Container Apps secret so the platform can pull the private image.

## Cleanup

```bash
terraform destroy
```

Confirm with `yes` and the sandbox disappears.
