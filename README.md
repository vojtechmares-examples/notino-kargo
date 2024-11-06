# notino-(k)argo

This demo is based on [kargo-advanced](https://github.com/akuity/kargo-advanced) example.

## Links

| **Name** | **URL** | **Note** |
| --- | --- | --- |
| ArgoCD | [`notino-argocd.maresdemo.com`](https://notino-argocd.maresdemo.com) | Crendetials: User: `admin`, Pass: `sIxEeez5-jC2ABD3` |
| Kargo | [`notino-kargo.maresdemo.com`](https://notino-kargo.maresdemo.com) | Credentials: User: `admin`, Pass: `admin` |
| Slides | [Google Slides](https://docs.google.com/presentation/d/1n5avpQIFkbXaGHVM4c5ZbJx18LAWTU8HNEJjwptrDeY/edit?usp=sharing) | |

## How to

1. Prepare DigitalOcean infrastructure:

    ```bash
    make infra-up
    ```

2. Export kubeconfig

    ```bash
    make kubeconfig

    export KUBECONFIG=$(pwd)/infrastructure/kubeconfig.yaml
    ```

3. Install ArgoCD, Argo Rollouts, Kargo

    ```bash
    make install-argocd
    make install-argorollouts
    make install-kargo
    ```

4. Install kargo and argocd cli

    ```bash
    ./scripts/download-cli.sh /usr/local/bin/kargo

    # argocd
    # macos:
    brew instal argocd
    ```

5. Login to Kargo and ArgoCD via cli

    ```bash
    kargo login https://notino-kargo.maresdemo.com --admin # password: admin
    argocd login notino-argocd.maresdemo.com # username: admin, password: sIxEeez5-jC2ABD3
    ```

6. Create ArgoCD resources

    ```bash
    argocd project create -f ./argocd/appproj.yaml
    argocd appset create ./argocd/appset.yaml

    # or via kubectl
    kubectl apply -f ./argocd
    ```

7. Create Kargo resources

    ```bash
    kargo apply -f ./kargo
    ```

8. Create Kargo credentials with GitHub PAT for repository-write access

    ```bash
    kargo credentials create github-creds \
      --project notino-demo \
      --username <your github username> \
      --repo-url <github repo url over https>
    ```

9. Simulate fake release of new docker image

    ```bash
    ./scripts/new-tag.sh
    ```