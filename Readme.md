# Swift Docker
A Dockerfile to have a Docker image to build Swift projects on Debian Stretch.

## Using the Dockerfile
Building Swift requires the ptrace capability. Docker build, by default, launches containers that do not have this capability. In order to be able to use this Dockerfile, you’ll have to disable this security restriction.  
One way to do it is edit `/etc/docker/daemon.json` and set the `seccomp-profile` key to `/etc/docker/seccomp.json` for instance (create the key if it does not exist yet). Then copy the `seccomp.json` file in this repository to the path you set in the daemon.json. Finally restart docker, building the image should now work.

Note: The `seccomp.json` in this repo disables all secure computing modes of Docker. You should not keep this config after you’ve built the Swift image. A better profile could probably be created, but for now it’ll do.
