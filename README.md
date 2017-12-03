# concourse-deploy-resource
[concourse.ci](https://concourse.ci/ "concourse.ci Homepage") [resource](https://concourse.ci/implementing-resources.html "Implementing a resource") for persisting build artifacts on a remote server and activating directory using rsync and ssh.

##Config
* `server|servers`: *Required* Server or list of servers on which to persist artifacts. If `servers` are used first one in the list will be used for `in` and `check` origins.
* `port`: *Optional* Server SSH port, default is port 22
* `remote_dir`: *Required* Directory to place artifacts on remote server(s)
* `remote_user`: *Required* User credential for login using ssh
* `private_key`: *Required* Key for the specified user
* `restart_service`: *Optional* Optionally restart a service on the remote host(s)

All config required for each of the `out` behavior.

###Example

``` yaml
resource_types:
- name: deploy-resource
  type: docker-image
  source:
      repository: scottsmith/concourse-deploy-resource
      tag: latest

resources:
- name: sync-resource
  type: deploy-resource
  source:
    server: server
    remote_dir: /var/sites
    user : user
    private_key: |
            ...

- name: sync-resource-multiple
  type: rsync-resource
  source:
    servers:
      - server1
      - server2
    remote_dir: /var/sites
    user : user
    private_key: |
            ...

jobs:
-name: my_great_job
  plan:
    ...
    put: sync-resource
      params:
        sync_dir: my_output_dir
        repo_name: your-project-name

    put: sync-resource
      params:
        sync_dir: my_output_dir
        rsync_opts:
          -Pav
          --del
          --chmod=Du=rwx,Dgo=rx,Fu=rw,Fog=r
```

##Behavior
### `check` : Check for new versions of artifacts
Return an empty version

### `in` : retrieve a given artifacts from `server`
Return an empty version

### `out` : place a new artifact on `server`
Generate a new `version` number an associated directory in `remote_dir` on `server` using the specified user credential.
Rsync across artifacts from the input directory to the server and re-create a symlink with the name `repo_name` to the generated directory name and output the `version`
#### Parameters

* `sync_dir`: *Optional.* Directory to be sync'd. If specified limit the directory to be sync'd to sync_dir. If not specified everything in the `put` will be sent (which could include container resources, whole build trees etc.)
* `repo_name`: *Required* The symbolic link name to the generated direct name pushed onto remote server
* `rsync_opts`: *Optional* Optional parameters to rsync
* `restart_service`: *Optional* Give a service name to be restarted. ie. php deploys can restart the php-fpm/apache2 service