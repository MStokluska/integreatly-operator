#!/usr/bin/env bash

# Compares current manifest vs manifest generated for master
manifest_compare() {
    sort $MASTER_FROM_BRANCH > $SORTED_FROM_BRANCH
    sort $CURRENT_MASTER > $SORTED_CURRENT_MASTER
    MANIFESTS_DIFF=$(diff --suppress-common-lines ${SORTED_FROM_BRANCH} ${SORTED_CURRENT_MASTER})
    if [ ! -z "$MANIFESTS_DIFF" ]; then
        echo "Difference found between master manifests"
        rm -f "$MASTER_FROM_BRANCH"
        rm -f "$SORTED_FROM_BRANCH"
        rm -f "$SORTED_CURRENT_MASTER"
        exit 0
    elif [ -z "$MANIFESTS_DIFF" ]; then
        echo "No difference found between the manifests"
        rm -f "$MASTER_FROM_BRANCH"
        rm -f "$SORTED_FROM_BRANCH"
        rm -f "$SORTED_CURRENT_MASTER"
        exit 0
    else 
        exit 1
    fi
}

# Generates the manifest, it can be either master or production manifest
manifest_generate() {
    FILEPATH="${CURRENT_DIR}/products/products.yaml"
    PRODUCTS=10
    # Generation manifest file
    GENERATION_FILE="${CURRENT_DIR}/prodsec-manifests/generation-file.txt"

    # Scan repos from the products.yaml file
    for (( i=0; i<=$PRODUCTS; i++))
    do
        PRODUCT_NAME=$(yq r ${FILEPATH} "products[$i].name")
        PRODUCT_VERSION=$(yq r ${FILEPATH} "products[$i].version")
        PRODUCT_VERSION_ID=$PRODUCT_NAME-$PRODUCT_VERSION
        PRODUCT_URL=$(yq r ${FILEPATH} "products[$i].url")
        PRODUCT_INSTALL_TYPE=$(yq r ${FILEPATH} "products[$i].installType")

        if [[ "$PRODUCT_INSTALL_TYPE" == *"$OLM_TYPE"* ]]; then
          TMP_DIR=$(mktemp -d)
          echo "Generating manifest for ${PRODUCT_NAME} - version ${PRODUCT_VERSION}"
          git clone -c advice.detachedHead=false --quiet --depth 1 -b ${PRODUCT_VERSION} ${PRODUCT_URL} ${TMP_DIR}
          cd ${TMP_DIR}
          go mod graph | cut -d " " -f 2 | tr @ - | while read x; do echo "${SERVICE_NAME}:${VERSION}/$PRODUCT_VERSION_ID/$x" >> "$GENERATION_FILE"; done
          cd ${CURRENT_DIR}
          rm -rf $TMP_DIR
        fi
    done

    # Dependencies used
    go mod graph | cut -d " " -f 2 | tr @ - | while read x; do echo "${SERVICE_NAME}:${VERSION}/$x" >> "$GENERATION_FILE"; done

    cat "$GENERATION_FILE" > "$FILE_NAME"

    echo "Manifest generated successfully, deleting temporary files"
    rm -f "$GENERATION_FILE"
}

CURRENT_DIR=$(pwd)

case $TYPE_OF_MANIFEST in
"master")
    case $OLM_TYPE in
      "integreatly-operator")
        OLM_TYPE="rhmi"
        VERSION="master"
        FILE_NAME="${CURRENT_DIR}/prodsec-manifests/rhmi-master-manifest.txt"
        SERVICE_NAME="services-rhmi"
        ;;
      "managed-api-service")
        OLM_TYPE="rhoam"
        VERSION="master"
        FILE_NAME="${CURRENT_DIR}/prodsec-manifests/rhoam-master-manifest.txt"
        SERVICE_NAME="services-rhoam"
        ;;
      *)
        echo "Invalid OLM_TYPE set"
        echo "Use \"integreatly-operator\" or \"managed-api-service\""
        exit 1
        ;;
    esac
    manifest_generate
    ;;
"compare")
        case $OLM_TYPE in
      "integreatly-operator")
        OLM_TYPE="rhmi"
        VERSION="master"
        FILE_NAME="${CURRENT_DIR}/prodsec-manifests/master-from-branch-manifest.txt"
        SERVICE_NAME="services-rhmi"
        MASTER_FROM_BRANCH="${CURRENT_DIR}/prodsec-manifests/master-from-branch-manifest.txt"
        SORTED_FROM_BRANCH="${CURRENT_DIR}/prodsec-manifests/sorted-master-from-branch-manifest.txt"
        CURRENT_MASTER="${CURRENT_DIR}/prodsec-manifests/rhmi-master-manifest.txt"
        SORTED_CURRENT_MASTER="${CURRENT_DIR}/prodsec-manifests/rhmi-master-manifest.txt"
        ;;
      "managed-api-service")
        OLM_TYPE="rhoam"
        VERSION="master"
        FILE_NAME="${CURRENT_DIR}/prodsec-manifests/master-from-branch-manifest.txt"
        SERVICE_NAME="services-rhoam"
        MASTER_FROM_BRANCH="${CURRENT_DIR}/prodsec-manifests/master-from-branch-manifest.txt"
        SORTED_FROM_BRANCH="${CURRENT_DIR}/prodsec-manifests/sorted-master-from-branch-manifest.txt"
        CURRENT_MASTER="${CURRENT_DIR}/prodsec-manifests/rhoam-master-manifest.txt"
        SORTED_CURRENT_MASTER="${CURRENT_DIR}/prodsec-manifests/rhoam-sorted-master-manifest.txt"
        ;;
      *)
        echo "Invalid OLM_TYPE set"
        echo "Use \"integreatly-operator\" or \"managed-api-service\""
        exit 1
        ;;
    esac
    manifest_generate
    manifest_compare
    ;;
"production")
    case $OLM_TYPE in
      "integreatly-operator")
        OLM_TYPE="rhmi"
        VERSION=$(grep integreatly-operator ${CURRENT_DIR}/deploy/olm-catalog/integreatly-operator/integreatly-operator.package.yaml | awk -F v '{print $2}')
        FILE_NAME="${CURRENT_DIR}/prodsec-manifests/rhmi-production-release-manifest.txt"
        SERVICE_NAME="services-rhmi"
        ;;
      "managed-api-service")
        OLM_TYPE="rhoam"
        VERSION=$(grep managed-api-service ${CURRENT_DIR}/deploy/olm-catalog/managed-api-service/managed-api-service.package.yaml | awk -F v '{print $3}')
        FILE_NAME="${CURRENT_DIR}/prodsec-manifests/rhoam-production-release-manifest.txt"
        SERVICE_NAME="services-rhoam"
        ;;
      *)
        echo "Invalid OLM_TYPE set"
        echo "Use \"integreatly-operator\" or \"managed-api-service\""
        exit 1
        ;;
    esac
    manifest_generate
    ;;
*)
    echo "Invalid type of manifest requested"
    echo "Use \"master\",\"production\" or \"compare\""
    exit 1
    ;;
esac
