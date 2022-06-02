# shelah-devops

DevOps pipelines for Shelah services and clients

# Running the CI/CD pipelines for Shelah services and clients

CI/CD pipelines are meant to run in Linux only, not Windows.

Docker must be running. If you are using a WSL environment, you can start the Docker daemon like this:

`sudo service docker start`

You must ensure that the `apdo` CLI tool is in the path, and set its environment variable to point to the 
pipeline album for Shelah projects. For example, you must do something like this:

* Add the bin folder of your CCL-DevOps installation to `$PATH`. For example, 
  `export PATH=/mnt/c/Users/aleja/Documents/Code/chateauclaudia-labs/ccl-chassis/devops/bin:$PATH`

* `$_CFG__PIPELINE_ALBUM` to identify the folder containing the CCL-DevOps pipeline definitions for your application.
  Typically this would be a folder in your application repo. For example, 
  `export _CFG__PIPELINE_ALBUM="/mnt/c/Users/aleja/Documents/Code/chateauclaudia-labs/shelah-repos/shelah-devops/pipeline_album"`

You can then you list the available pipelines with commands like

`apdo pipeline list`

and (provided Docker is running), you may run a specific pipeline iwth

`apdo pipeline run 5001` (if `5001` is a valid pipeline id for the album you are pointing to)
