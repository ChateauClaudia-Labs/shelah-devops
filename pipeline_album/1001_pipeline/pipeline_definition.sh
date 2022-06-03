#!/usr/bin/env bash

source ${_CFG__PIPELINE_ALBUM}/epoch_commons.sh

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
_CFG__pipeline_description() {
    echo "
    Flow type:                          Docker flow
    Deployable built:                   ${_CFG__DEPLOYABLE}
    Deployable version:                 v${_CFG__DEPLOYABLE_VERSION}
    Packaged as:                        Docker container for image ${_CFG__DEPLOYABLE_IMAGE}
    Deployed to:                        UAT environment in local Linux host (same host in which pipeline is run)
    Secrets:                            ${SECRETS_FOLDER}
    Shelah config directory:            ${SHELAH_CONFIG_DIRECTORY}
    "
}

# Single-line description suitable for use when listing multiple pipelines
_CFG__pipeline_short_description() {
    echo "Deploys ${_CFG__DEPLOYABLE} v${_CFG__DEPLOYABLE_VERSION} as a Linux container locally to ${ENVIRONMENT}"
}

# Release version that is to be built
export _CFG__DEPLOYABLE="shelah_gateway"
export _CFG__DEPLOYABLE_VERSION="0.1.0"
export _CFG__DEPLOYABLE_GIT_BRANCH="v${_CFG__DEPLOYABLE_VERSION}"

# This is the path from (and including) the root folder for the repo all to way to the deployable
export _CFG__DEPLOYABLE_RELATIVE_PATH="shelah/${_CFG__DEPLOYABLE}"

# Defines the name (& tag) for the deployable's image to be created by the pipeline. If there is no tag, Docker will
# by default put a tag of ":latest"
#
export _CFG__DEPLOYABLE_IMAGE="${_CFG__DEPLOYABLE}:latest"

# These are inputs to the setting of _CFG__DEPLOYMENT_DOCKER_OPTIONS
#
# That means that they determine what environment is being mounted in the deployable's container by 
# this pipeline.
# That's mediated by the function epoch_commons.sh::_CFG__set_deployment_docker_options, which uses
# these inputs to define _CFG__DEPLOYMENT_DOCKER_OPTIONS
#
# The function _CFG__set_deployment_docker_options is invoked by CCL-DevOps
#
export ENVIRONMENT="UAT_ENV"
export SECRETS_FOLDER=${A6I_ROOT}/${ENVIRONMENT}/secrets
