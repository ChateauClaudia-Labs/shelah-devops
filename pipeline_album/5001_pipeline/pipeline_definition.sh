#!/usr/bin/env bash

source ${_CFG__PIPELINE_ALBUM}/epoch_commons.sh

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
_CFG__pipeline_description() {
    echo "
    Flow type:                          Docker flow
    Deployable built:                   ${_CFG__DEPLOYABLE}
    Deployable version:                 Alex's 'dev' branch in host CC-Labs-2
    Packaged as:                        Docker container for image '${_CFG__DEPLOYABLE_IMAGE}'
    Deployed to:                        Local Linux host (same host in which pipeline is run)
    Secrets:                            ${SECRETS_FOLDER}
    Shelah config directory:            ${SHELAH_CONFIG_DIRECTORY}
    "
}

# Single-line description suitable for use when listing multiple pipelines
_CFG__pipeline_short_description() {
    echo "Deploys local ${_CFG__DEPLOYABLE} dev branch as a Linux container to ${ENVIRONMENT} (for user Alex in host CC-Labs-2)"
}

# Release version that is to be built
export _CFG__DEPLOYABLE="shelah_gateway"
export _CFG__DEPLOYABLE_GIT_BRANCH="dev"
export _CFG__DEPLOYABLE_VERSION="dev"


# Inputs for function: epoch_commons.sh::_CFG__set_build_docker_options
#
# Purpose: function is called by CCL-DevOps to set _CFG__BUILD_DOCKER_OPTIONS
#
export MOUNT_SHELAH_GIT_PROJECT=1
export _CFG__DEPLOYABLE_GIT_URL="/mnt/c/Users/aleja/Documents/Code/chateauclaudia-labs/shelah-repos/shelah"
export _CFG__TESTDB_GIT_URL="/mnt/c/Users/aleja/Documents/Code/chateauclaudia-labs/shelah-repos/${_CFG__DEPLOYABLE}-testdb"

# Defines the name (& tag) for the deployable's image to be created by the pipeline. If there is no tag, Docker will
# by default put a tag of ":latest"
#
_CFG__DEPLOYABLE_IMAGE="${_CFG__DEPLOYABLE}:dev"

# Inputs for function: epoch_commons.sh::_CFG__set_deployment_docker_options
#
# Purpose: function is called by CCL-DevOps to set _CFG__DEPLOYMENT_DOCKER_OPTIONS
#
export ENVIRONMENT="UAT_ENV"
export SECRETS_FOLDER=${REPOS_ROOT}/${ENVIRONMENT}/secrets
