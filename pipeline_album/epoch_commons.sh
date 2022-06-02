# This file defines some variables & functions that are common across multiple pipelines.
#
# Normally, they define an "epoch", i.e., a period of time during which pipelines are using a stable set of infrastructure 
# dependencies (e.g, Python version, Ubuntu version, application GIT URL, ....)
#
# Any specific pipeline can overwrite any of these values by simply re-defining the variable in question, since the pattern
# is to "source" this file as the first thing that is done in a pipeline definition script.
#
export _CFG__UBUNTU_IMAGE="ubuntu:22.04"
export _CFG__UBUNTU_PYTHON_PACKAGE="python3.10"
export _CFG__BUILD_SERVER="shelah-build-server"


# We draw a distinction between the "application" vs the "deployable(s)":
#
#       1. An application may consist of multiple microservices, each of which is a "deployable"
#       2. GIT repos are at the level of volatility, which means usually multiple microservices are in the same GIT
#               repo. Usual pattern is: one repo for the client services (CLI, UI, ...), and one repo for the server-side
#               microservices
#       3. What we call a "deployable" here corresponds to 1 microservice, which entails 1 Python package (with its own
#               microservice-specific setup.cfg and src folder)
#       4. So an "application" has 1+ repos, and each repo has 1+ "deployables"
#       5. Test database repos are at the level of the "application" to allow for testing multiple microservices together, while segregating
#               microservice-specific tests in subfolders.
#       6. Pipelines are the level of a "deployable". 
#       7. Configuration is at the level of a "deployable".
#       8. Therefore, a pipeline for a microservice X will need GIT repos for more then just X, since the GIT repo may bring
#               along code and tests for other microservices as well, even if the pipeline will the concern itself with only
#               building X and only testing X (by going to appropriate sub-folders in the repo for X and for X's tests)
#

export _CFG__APPLICATION="shelah"

export _CFG__DEPLOYABLE_GIT_URL="https://github.com/ChateauClaudia-Labs/${_CFG__APPLICATION}.git"

export _CFG__TESTDB_GIT_URL="https://github.com/ChateauClaudia-Labs/${_CFG__APPLICATION}-testdb.git"

export _CFG__TESTDB_REPO_NAME="${_CFG__APPLICATION}-testdb"

# We need to set the variable $REPOS_ROOT which is used by the Shelah pipeline definitions as the root folder
# above test environments like UAT.
# We set it based on these considerations: ff we call <REPOS_ROOT> the folder where Shelah repos exist, then we know that:
#
#   * The environment is usually <REPOS_ROOT>/${ENVIRONMENT}. Example: <REPOS_ROOT>/UAT_ENV
#   * ${_CFG__PIPELINE_ALBUM} points to <REPOS_ROOT>/${_CFG__APPLICATION}-devops/pipeline_album
#   
# This motivates how the following is set up
REPOS_ROOT=${_CFG__PIPELINE_ALBUM}/../../


export SHELAH_CONFIG_DIRECTORY=${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}

export TEST_SHELAH_CONFIG_DIRECTORY=${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}/${_CFG__DEPLOYABLE}_testdb_config

_CFG__set_build_docker_options() {

    echo "${_SVC__INFO_PROMPT} ... Determining approach for how container can access the GIT repo:"
    if [ ! -z ${MOUNT_SHELAH_GIT_PROJECT} ]
        then
            echo "${_SVC__INFO_PROMPT}        => by mounting this drive:"
            echo "${_SVC__INFO_PROMPT}        => ${_CFG__DEPLOYABLE_GIT_URL}"
            if [ ! -d ${_CFG__DEPLOYABLE_GIT_URL} ]
                then
                    echo "${_SVC__ERR_PROMPT} Directory doesn't exist, so can't mount it:"
                    echo "      ${_CFG__DEPLOYABLE_GIT_URL}"
                    echo
                    echo "${_SVC__ERR_PROMPT} Aborting build..."
                    exit 1
            fi
            export SHELAH_URL_CLONED_BY_CONTAINER="/home/${_CFG__APPLICATION}"
            export GIT_REPO_MOUNT_DOCKER_OPTION=" -v ${_CFG__DEPLOYABLE_GIT_URL}:${SHELAH_URL_CLONED_BY_CONTAINER}"
        else
            echo "${_SVC__INFO_PROMPT}        => from this URL:"
            echo "${_SVC__INFO_PROMPT}        => ${_CFG__DEPLOYABLE_GIT_URL}"
            export SHELAH_URL_CLONED_BY_CONTAINER="${_CFG__DEPLOYABLE_GIT_URL}"
    fi    

    echo " -e _CFG__DEPLOYABLE_GIT_URL=${SHELAH_URL_CLONED_BY_CONTAINER} " \
            $GIT_REPO_MOUNT_DOCKER_OPTION > /tmp/_CFG__BUILD_DOCKER_OPTIONS.txt
    export _CFG__BUILD_DOCKER_OPTIONS=`cat /tmp/_CFG__BUILD_DOCKER_OPTIONS.txt`
}

# This comment applies to how we implement these functions:
#
#   * _CFG__set_testrun_docker_options
#   * _CFG__set_linux_test_conda_options
#
# We expect the test database to already have an `${_CFG__DEPLOYABLE}_config.toml` file geared to development-time testing.
# That means that the paths referenced in that `${_CFG__DEPLOYABLE}_config.toml` file are expected to include hard-coded
# directories for the developer's machine.
#
# These hard-coded directories in the host won't work when the tests are run inside the SHELAH container, so we 
# will have to replace them by paths in the container file system. However, we don't want to modify the
# test database's `${_CFG__DEPLOYABLE}_config.toml` file since its host hard-coded paths are needed at development time.
# Therefore, the logic of CCL-DevOps if for container to apply this logic when running CCL_Devops' testrun.sh:
#
#   1. Clone the GIT repo that contains the test database into /home/work, creating /home/work/${_CFG__DEPLOYABLE}-testdb inside
#      the container
#   2. Rely on the environment variable $INJECTED_CONFIG_DIRECTORY to locate the folder where the SHELAH configuration
#      file resides. 
#      This environment variable is needed to address the following problem with SHELAH's test harness, and specifcially by
#      ${_CFG__DEPLOYABLE}.testing_framework.a6i_skeleton_test.py:
#
#           The test harness by default assumes that the SHELAH configuration is found in 
#
#                    '../../../../test_db'
#
#           with the path relative to that of `a6i_skeleton_test.py` in the container, which is 
#
#                   /usr/local/lib/python3.9/dist-packages/${_CFG__DEPLOYABLE}/testing_framework/a6i_skeleton_test.py
#
#      because of the way how pip installed SHELAH inside the container. 
#
#      This is addresed by:
#           - setting the environment variable $INJECTED_CONFIG_DIRECTORY to /home/${_CFG__DEPLOYABLE}_testdb_config
#           - this will cause the test harness to look for SHELAH's configuration in the folder $INJECTED_CONFIG_DIRECTORY
#           - additionally, read the value of another environment variable, $TEST_SHELAH_CONFIG_DIRECTORY, from the
#             pipeline definition (in pipeline_album/<pipeline_id>/pipeline_definition.sh)
#           - this way the pipeline's choice for what ${_CFG__DEPLOYABLE}_config.toml to use for testing will come from looking
#             in $TEST_SHELAH_CONFIG_DIRECTORY in the host
#           - lastly, we mount $TEST_SHELAH_CONFIG_DIRECTORY as /home/${_CFG__DEPLOYABLE}_testdb_config in the container, which is
#             where the container-run test harness will expect it (since that's the value of $INJECTED_CONFIG_DIRECTORY)
#
_CFG__set_testrun_docker_options() {

    echo "${_SVC__INFO_PROMPT} ... Determining approach for how container can access the GIT testdb repo:"
    if [ ! -z ${MOUNT_SHELAH_GIT_PROJECT} ]
        then
            echo "${_SVC__INFO_PROMPT}        = by mounting this drive:"
            echo "${_SVC__INFO_PROMPT}        => ${_CFG__TESTDB_GIT_URL}"
            if [ ! -d ${_CFG__TESTDB_GIT_URL} ]
                then
                    echo "${_SVC__ERR_PROMPT} Directory doesn't exist, so can't mount it:"
                    echo "      ${_CFG__TESTDB_GIT_URL}"
                    echo
                    echo echo "${_SVC__ERR_PROMPT} Aborting testrun..."
                    exit 1
            fi
            export SHELAH_TESTDB_URL_CLONED_BY_CONTAINER="/home/${_CFG__APPLICATION}-testdb"
            export GIT_REPO_MOUNT_DOCKER_OPTION=" -v ${_CFG__TESTDB_GIT_URL}:${SHELAH_TESTDB_URL_CLONED_BY_CONTAINER}"
        else
            echo "${_SVC__INFO_PROMPT}        => from this URL:"
            echo "${_SVC__INFO_PROMPT}        => ${_CFG__TESTDB_GIT_URL}"
            export SHELAH_TESTDB_URL_CLONED_BY_CONTAINER="${_CFG__TESTDB_GIT_URL}"
    fi    

    echo    " -e _CFG__TESTDB_GIT_URL=${SHELAH_TESTDB_URL_CLONED_BY_CONTAINER} " \
            " -e INJECTED_CONFIG_DIRECTORY=/home/${_CFG__DEPLOYABLE}_testdb_config" \
            " -e SHELAH_CONFIG_DIRECTORY=/home/${_CFG__DEPLOYABLE}_testdb_config" \
            " -v $TEST_SHELAH_CONFIG_DIRECTORY:/home/${_CFG__DEPLOYABLE}_testdb_config" \
            "${GIT_REPO_MOUNT_DOCKER_OPTION} "> /tmp/_CFG__TESTRUN_DOCKER_OPTIONS.txt
    export _CFG__TESTRUN_DOCKER_OPTIONS=`cat /tmp/_CFG__TESTRUN_DOCKER_OPTIONS.txt`
}



# This function will be invoked by CCL-DevOps. It is used to create _CFG__DEPLOYMENT_DOCKER_OPTIONS.
#
# This impelementation is SHELAH-specific and requires that the following have been previously
# set in the pipeline definition:
#
#   -${SHELAH_CONFIG_DIRECTORY}
#   -${SECRETS_FOLDER}
#
_CFG__set_deployment_docker_options() {

    # Check that Shelah config file exists
    [ ! -f ${SHELAH_CONFIG_DIRECTORY}/${_CFG__DEPLOYABLE}_config.toml ] && echo \
        && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' is improperly configured:" \
        && echo "${_SVC__ERR_PROMPT} It expects Shelah config file, which doesn't exist:" \
        && echo "${_SVC__ERR_PROMPT}     ${SHELAH_CONFIG_DIRECTORY}/${_CFG__DEPLOYABLE}_config.toml" \
        && echo \
        && exit 1

    # Check that mounted volumes for the SHELAH environment exist
    [ ! -d ${SECRETS_FOLDER} ] && echo \
            && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' is improperly configured:" \
            && echo "${_SVC__ERR_PROMPT} It expects a non-existent folder called "\
            && echo "    ${SECRETS_FOLDER}." \
            && echo \
            && exit 1

    echo    " -e SHELAH_CONFIG_DIRECTORY=/home/${_CFG__DEPLOYABLE}/config" \
            " -v ${SECRETS_FOLDER}:/home/${_CFG__DEPLOYABLE}/secrets " \
            " -v ${SHELAH_CONFIG_DIRECTORY}:/home/${_CFG__DEPLOYABLE}/config" > /tmp/_CFG__DEPLOYMENT_DOCKER_OPTIONS.txt

    export _CFG__DEPLOYMENT_DOCKER_OPTIONS=`cat /tmp/_CFG__DEPLOYMENT_DOCKER_OPTIONS.txt`

}


