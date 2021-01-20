#!/usr/bin/env bash

# This script generates a manifest of the integreatly-operator which includes the direct and indirect dependencies 
# used. The generated manifest corresponds to a released version and is located in : ../rhoam-manifests/

MANIFEST_TYPE=$1

# Compares current manifest vs manifest generated for master
manifest_compare() {
    RHOAM_VERSION="master"
    FILE_NAME="rhoam-master-from-branch-manifest.txt"
    RHOAM_MASTER_FROM_BRANCH="rhoam-manifests/rhoam-master-from-branch-manifest.txt"
    RHOAM_CURRENT_MASTER="rhoam-manifests/rhoam-master-manifest.txt"
    RHOAM_SORTED_MASTER="rhoam-manifests/rhoam-master-sorted-manifest.txt"

    manifest_generate

    # Additional sorting of the master manifest is required as it seems that prow sorts files in a different manner.
    sort -u "$RHOAM_CURRENT_MASTER" > "$RHOAM_SORTED_MASTER"

    MANIFESTS_DIFF=$(diff --suppress-common-lines ${RHOAM_MASTER_FROM_BRANCH} ${RHOAM_SORTED_MASTER})
    if [ ! -z "$MANIFESTS_DIFF" ]; then
        echo "Difference found between master manifests, run make rhoam/manifest and push PR again"
        
        # Delete sorted files
        rm -f "$RHOAM_MASTER_FROM_BRANCH"
        rm -f "$RHOAM_SORTED_MASTER"
        exit 1
    else
        echo "No difference found between the manifests"

        # Delete sorted files
        rm -f "$RHOAM_MASTER_FROM_BRANCH"
        rm -f "$RHOAM_SORTED_MASTER"
        exit 0
    fi
}

# Generates the manifest, it can be either master or production manifest
manifest_generate() {
    # Set the service name and version
    SERVICE_NAME="services-rhoam"

    # Pre-filetered manifest file
    PRE_SORTED_FILE="rhoam-manifests/pre-sorted-file.txt"

    # Create PRE_SORTED_FILE
    touch $PRE_SORTED_FILE

    # Dependencies used
    go mod graph | cut -d " " -f 2 | tr @ - | while read x; do echo "${SERVICE_NAME}:${RHOAM_VERSION}/$x" >> "$PRE_SORTED_FILE"; done

    # Remove repeating dependencies
    sort -u "$PRE_SORTED_FILE" > "rhoam-manifests/$FILE_NAME"

    # Delete pre-sorted file
    rm -f "$PRE_SORTED_FILE"
}

case $MANIFEST_TYPE in
"master")
    RHOAM_VERSION="master"
    FILE_NAME="rhoam-master-manifest.txt"
    manifest_generate
    ;;
"compare")
    manifest_compare
    ;;
*)
if [ -z "$MANIFEST_TYPE" ]
    then
        RHOAM_VERSION=$(grep managed-api-service.v deploy/olm-catalog/managed-api-service/managed-api-service.package.yaml | tail -c 6)
        FILE_NAME="rhoam-production-release-manifest.txt"
        manifest_generate
        exit 0
fi
    echo "Invalid type of manifest requested"
    echo "Use \"production\" or \"master\""
    exit 1
    ;;
esac