FROM scratch

# Core bundle labels.
LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=integreatly-operator
LABEL operators.operatorframework.io.bundle.channels.v1=rhmi
LABEL operators.operatorframework.io.bundle.channel.default.v1=rhmi
LABEL operators.operatorframework.io.metrics.builder=operator-sdk-v1.11.0+git
LABEL operators.operatorframework.io.metrics.mediatype.v1=metrics+v1
LABEL operators.operatorframework.io.metrics.project_layout=go.kubebuilder.io/v2

# Labels for testing.
LABEL operators.operatorframework.io.test.mediatype.v1=scorecard+v1
LABEL operators.operatorframework.io.test.config.v1=tests/scorecard/

# Copy files to locations specified by labels.
COPY bundles/integreatly-operator/2.9.1/manifests /manifests/
COPY bundles/integreatly-operator/2.9.1/metadata /metadata/
COPY bundles/integreatly-operator/2.9.1/tests/scorecard /tests/scorecard/
