This folder contains patches to be able to build patched versions of Swift (the patches basically contains a remote add and checkout of a custom branch of Swift in the Dockerfile).
We transitionned to this way of patching Swift over the previous way, which consisted in having one branch per patch, a little bit after the release of Swift 5.2.1.
