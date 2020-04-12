# Quick Reference
### `Dockerfile` Link
https://github.com/happn-tech/swift-docker/blob/master/context_stretch/Dockerfile

### Where to File Issues
https://github.com/happn-tech/swift-docker/issues

### Maintained By
[happn](https://github.com/happn-tech/)


# What Is This Image?
This image contains the Swift compiler for Debian Stretch. It is built by the [Dockerfile](https://github.com/happn-tech/swift-docker/blob/master/context_stretch/Dockerfile) in the [`context_stretch`](https://github.com/happn-tech/swift-docker/blob/master/context_stretch/) folder of [this GitHub repository](https://github.com/happn-tech/swift-docker).

### Using the Compiled Files Outside of Docker
The image contains a `.deb` file you can retrieve at path `$SWIFTLANG_LIBS_DEB_PATH`. The deb contains the Swift libs, against which all Swift executables are linked.
Installing the deb on a Debian Stretch install should allow you to run the binaries produced by the Swift compiler inside this Docker image.

There is an option you can pass to swift to try and statically link the Swift libs (`--static-swift-stdlib`), however this option apparently [does not work on Linux](https://bugs.swift.org/browse/SR-648).

### Using the Compiler Outside of Docker
The image also contains the `.deb` file to install the Swift compiler directly on a Debian Stretch install at path `$SWIFTLANG_DEB_PATH`.

### Running the REPL
To run the Swift REPL, you’ll have to run swift directly, **and** disable the confinement so that ptrace works in the container. For instance you can do something like:

```bash
docker run --security-opt=seccomp:unconfined -it --rm happn/swift swift
```
