# This will define the execute_docker_flow_step function
source ${_CFG__PIPELINE_ALBUM}/execution_commons.sh

execute_docker_flow_step request_build.sh "build step"

execute_docker_flow_step request_provisioning.sh "provisioning step"

execute_docker_flow_step request_testrun.sh "testrun step"

execute_docker_flow_step request_deployment.sh "deployment step"

export CONTAINER_FOR_DEPLOYABLE=$(docker ps -q -l)
abort_pipeline_step_on_error
echo "${_SVC__INFO_PROMPT} ... ${_CFG__DEPLOYABLE} is up in container ${CONTAINER_FOR_DEPLOYABLE}"


