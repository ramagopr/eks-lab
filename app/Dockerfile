# Step 5b – "our" app: podinfo plus our own branding and version.
FROM ghcr.io/stefanprodan/podinfo:6.7.1

ARG VERSION=dev
LABEL org.opencontainers.image.source="https://github.com/ramagopr/eks-lab" \
      org.opencontainers.image.version="${VERSION}"

ENV PODINFO_UI_COLOR="#1F3A5F" \
    PODINFO_UI_MESSAGE="eks-lab build ${VERSION} – built by GitHub Actions, deployed by Argo CD"
