#!/bin/sh
set -e

# 配置默认值
REGISTRY="${REGISTRY:-registry.hub.docker.com}"
REPO_PREFIX="${REPO_PREFIX:-devcm}"

echo "========================================="
echo "Building Docker Image with Buildah"
echo "========================================="

# 验证必需的环境变量
if [ -z "${GIT_TAG}" ]; then
  echo "Error: GIT_TAG is not set!"
  exit 1
fi

if [ -z "${REGISTRY_USERNAME}" ] || [ -z "${REGISTRY_PASSWORD}" ]; then
  echo "Error: Registry credentials not set!"
  exit 1
fi

# 从 GIT_TAG 解析镜像目录和版本
IMAGE_DIR=$(echo ${GIT_TAG} | rev | cut -d'-' -f2- | rev)
VERSION=$(echo ${GIT_TAG} | rev | cut -d'-' -f1 | rev)

# 验证解析结果
if [ -z "${IMAGE_DIR}" ] || [ -z "${VERSION}" ]; then
  echo "Error: Failed to parse GIT_TAG: ${GIT_TAG}"
  exit 1
fi

# 构建路径
CONTEXT_PATH="images/${IMAGE_DIR}"
DOCKERFILE_PATH="${CONTEXT_PATH}/Dockerfile"

echo ""
echo "Build Configuration:"
echo "  Tag:           ${GIT_TAG}"
echo "  Image Dir:     ${IMAGE_DIR}"
echo "  Version:       ${VERSION}"
echo "  Context:       ${CONTEXT_PATH}"
echo "  Dockerfile:    ${DOCKERFILE_PATH}"
echo "  Registry:      ${REGISTRY}"
echo "  Repository:    ${REGISTRY}/${REPO_PREFIX}/${IMAGE_DIR}"
echo ""

# 验证 Dockerfile 存在
if [ ! -f "${DOCKERFILE_PATH}" ]; then
  echo "Error: Dockerfile not found at ${DOCKERFILE_PATH}"
  exit 1
fi

# 登录镜像仓库
echo "Logging in to registry..."
buildah login --username "${REGISTRY_USERNAME}" --password "${REGISTRY_PASSWORD}" --tls-verify=false "${REGISTRY}"

# 配置镜像源（如果设置了 IMAGE_MIRROR）
if [ -n "${IMAGE_MIRROR}" ]; then
  echo ""
  echo "Configuring registry mirror: ${IMAGE_MIRROR}"
  mkdir -p /etc/containers
  cat > /etc/containers/registries.conf <<EOF
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "${IMAGE_MIRROR}"
insecure = false
EOF
fi

# 构建镜像目标
IMAGE_WITH_VERSION="${REGISTRY}/${REPO_PREFIX}/${IMAGE_DIR}:${VERSION}"
IMAGE_WITH_LATEST="${REGISTRY}/${REPO_PREFIX}/${IMAGE_DIR}:latest"

echo ""
echo "Building image..."
echo "  Version tag: ${IMAGE_WITH_VERSION}"
echo "  Latest tag:  ${IMAGE_WITH_LATEST}"
if [ -n "${IMAGE_MIRROR}" ]; then
  echo "  Image mirror: ${IMAGE_MIRROR}"
fi
if [ -n "${APT_MIRROR}" ]; then
  echo "  APT mirror:   ${APT_MIRROR}"
fi
echo ""

# 执行 Buildah 构建
buildah bud \
  --format docker \
  --platform linux/amd64 \
  --build-arg VERSION="${VERSION}" \
  --build-arg APT_MIRROR="${APT_MIRROR}" \
  --tag "${IMAGE_WITH_VERSION}" \
  --tag "${IMAGE_WITH_LATEST}" \
  --tls-verify=false \
  -f "${DOCKERFILE_PATH}" \
  "${CONTEXT_PATH}"

echo ""
echo "Pushing images to registry..."

buildah push --tls-verify=false "${IMAGE_WITH_VERSION}"
echo "  Pushed: ${IMAGE_WITH_VERSION}"

buildah push --tls-verify=false "${IMAGE_WITH_LATEST}"
echo "  Pushed: ${IMAGE_WITH_LATEST}"

echo ""
echo "========================================="
echo "Build Completed Successfully!"
echo "========================================="
echo "Published Images:"
echo "  - ${IMAGE_WITH_VERSION}"
echo "  - ${IMAGE_WITH_LATEST}"
echo ""
