# Supported Tags and Respective `Dockerfile` Links
- `4.2`, `4.2.1`, `latest` — [Dockerfile](https://github.com/happn-tech/swift-docker/blob/f45ce1d69480207fb8833d27d0cad7e6ceb4fceb/Dockerfile)

# Quick Reference
##### Where to File Issues
https://github.com/happn-tech/swift-docker/issues

##### Maintained By
[happn](https://github.com/happn-tech/)

##### Supported architectures
`amd64`

# How to Use This Image

##### Building a Swift Project
The entry point of the image is a script that takes a git URL, a set of optional dependencies and build the package at the given URL in `/mnt/output`. You can retrieve the built product by mounting `/mnt/output`. Don’t forget to install the swiftlang-libs deb (available in the resulting “products” folder after the build is successful) before running the executable outside the Docker.

Example of use:
```bash
docker run -v "$(pwd)/VaporBuild:/mnt/output" --rm -it happn/swift-builder https://github.com/vapor/vapor.git=master libssl1.0-dev zlib1g-dev pkg-config
#Point by point:
#   docker run                                  Run docker
#   -v "$(pwd)/VaporBuild:/mnt/output"          Mount /mnt/output in ./VaporBuild (in order to retrieve the built products)
#   --rm -it                                    Remove the container after the build is complete, and attach with tty while running
#   happn/swift-builder                         The image to run
#   https://github.com/vapor/vapor.git=master   The URL of the project to build, with the branch/tag/commit to build (here master; optional)
#   libssl1.0-dev zlib1g-dev pkg-config         The dependencies required to build the project
```

 

##### Running the REPL
To run the Swift REPL, you’ll have to override the entrypoint, **and** disable the confinement so that ptrace works in the container. For instance you can do something like:

```bash
docker run --security-opt=seccomp:unconfined -it --rm --entrypoint swift happn/swift-builder
```
