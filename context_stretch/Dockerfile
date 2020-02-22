FROM debian:stretch-slim AS swiftlang_builder
LABEL maintainer="François Lamboley <francois.lamboley@happn.com>"
LABEL description="Compiles and creates a package of Apple’s Swift programming language. This image should not be used: it is a temporary image used by the next image in the Dockerfile."

# Exactly ONE of SWIFT_TAG and SWIFT_BRANCH must be set to a non-empty string
# SWIFT_TAG must be set to a Swift tag, minus the "swift-" prefix
ARG SWIFT_BRANCH
ARG SWIFT_TAG=5.0.1-RELEASE
ARG SWIFT_PRESET=buildbot_linux

# Should be set to `dpkg --print-architecture`
# FWIW, lscpu | grep Architecture | awk '{print $2}' gives x86_64 for amd64
ARG ARCH=amd64

# Not meant to be customized
ARG OUTPUT_PATH=/mnt/output

ENV SWIFT_TAG=${SWIFT_TAG} \
    SWIFT_BRANCH=${SWIFT_BRANCH}
ENV SWIFT_VERSION=${SWIFT_TAG}${SWIFT_BRANCH}
ENV SWIFT_ARCHIVE_OUTPUT_NAME="swift${SWIFT_TAG:+-tag-}${SWIFT_TAG}${SWIFT_BRANCH:+-scheme-}${SWIFT_BRANCH}-${ARCH}"
ENV SWIFT_ARCHIVE_OUTPUT_PATH="${OUTPUT_PATH}/${SWIFT_ARCHIVE_OUTPUT_NAME}.tar.gz"

ENV SWIFTLANG_DEB_NAME="swiftlang_${SWIFT_VERSION}-1~mkdeb1_${ARCH}" \
    SWIFTLANG_LIBS_DEB_NAME="swiftlang-libs_${SWIFT_VERSION}-1~mkdeb1_${ARCH}"
ENV SWIFTLANG_DEB_PATH="${OUTPUT_PATH}/${SWIFTLANG_DEB_NAME}.deb" \
    SWIFTLANG_LIBS_DEB_PATH="${OUTPUT_PATH}/${SWIFTLANG_LIBS_DEB_NAME}.deb"



# Let’s make sure ptrac’ing any process from the user that launched it is
# allowed (this is needed for lldb tests).
# https://askubuntu.com/a/148882
# This does not detect all the tests problems though; you should make sure there
# is an empty seccomp profile when building Swift via Docker, as described in
# the Readme of this repo.

#RUN echo 0 | tee /proc/sys/kernel/yama/ptrace_scope
RUN test "$(cat /proc/sys/kernel/yama/ptrace_scope)" = "0"



RUN mkdir -p "${OUTPUT_PATH}"

# Install packages. We install SWIG from testing because we need version 3.0.12.
# If needed, we can install clang-6.0 instead of the default clang from stretch:
# in some cases, when compiling master, I had a test (lane-release.llbuild) that
# failed randomly. Compiling Swift with clang 6.0 (from backports) fixed it.
# Other things to do when compiling Swift with clang 6.0:
#    - Install clang-6.0 in the other image of this Dockerfile
#    - Uncomment the update alternative RUN actions (in both images)
#    - Update the swiftlang mkdeb recipe to have a dependency to clang-6.0
COPY apt_prefs /etc/apt/preferences.d/pinning.pref
COPY debian_testing.list /etc/apt/sources.list.d/debian_testing.list
COPY debian_backports.list /etc/apt/sources.list.d/debian_backports.list
RUN apt-get update && apt-get install -y --no-install-recommends \
# Swift compilation dependencies (vim is only for two libdispatch tests…)
  clang \
# clang-6.0 \
  cmake \
  file \
  git \
  icu-devtools \
  libblocksruntime-dev \
  libbsd-dev \
  libcurl4-openssl-dev \
  libedit-dev \
  libicu-dev \
  libncurses5-dev \
  libpython-dev \
  libsqlite3-dev \
  libxml2-dev \
  make \
  ninja-build \
  pkg-config \
  python3 \
  rsync \
  swig \
  systemtap-sdt-dev \
  tzdata \
  unzip \
  uuid-dev \
  vim \
# To be able to clone the Swift repo & download stuff via https in general
  ca-certificates \
# To install Go (to install mkdeb) from archive (the golang-go package is too old for our needs on Stretch)
  curl \
&& rm -rf /var/lib/apt/lists/*
# We installed clang-6.0 from backport, we need to install the alternatives…
#RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-6.0 1000 && \
#    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-6.0 1000 && \
#    update-alternatives --install /usr/bin/cc cc /usr/bin/clang-6.0 1000

# Install Go (to install mkdeb…)
WORKDIR "/usr/local"
RUN ["/bin/bash", "-c", "set -eo pipefail && \
  curl -sSL https://dl.google.com/go/go1.12.linux-${ARCH}.tar.gz | tar xz && \
  ln -s /usr/local/go/bin/go /usr/local/bin/go && \
  ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt"]
ENV GOROOT=/usr/local/go GOPATH=/usr/local/gohome
# Install mkdeb
RUN set -e && \
    go get mkdeb.sh/cmd/mkdeb && \
    ln -s /usr/local/gohome/bin/mkdeb /usr/local/bin/mkdeb



# All further operations are done as an arbitrary user named “swift”
# (because one of Swift’s test fails if run as root)

RUN useradd swift && mkdir "/home/swift" && chown swift:users "/home/swift" "${OUTPUT_PATH}"
USER swift:users


# Get Swift’s source and compile them

WORKDIR "/tmp"
RUN mkdir "swift-built" && mkdir "swift-source"
WORKDIR "swift-source"
RUN git clone --depth 1 --recursive "https://github.com/apple/swift.git"
RUN git -C ./swift fetch --tags && git -C ./swift checkout ${SWIFT_TAG:+swift-}${SWIFT_TAG} ${SWIFT_BRANCH} && \
    ./swift/utils/update-checkout --skip-history --clone && \
    ./swift/utils/update-checkout --skip-history ${SWIFT_TAG:+--tag} ${SWIFT_TAG:+swift-}${SWIFT_TAG} ${SWIFT_BRANCH:+--scheme} ${SWIFT_BRANCH} && \
    git -C ./swift-corelibs-foundation remote add frizlab https://github.com/Frizlab/swift-corelibs-foundation.git && git -C ./swift-corelibs-foundation fetch frizlab && git -C ./swift-corelibs-foundation checkout 5.2.1-RELEASE_fix-operation-queue-and-disable-failing-tests
# Fix a bug where the resulting tarball would have a symlink to a file pointing
# to the original source folder. Not sure why the bug happens (probably because
# cmake version is too old on Debian?). The fix creates the symlink **before**
# running cmake, so that it can resolve the link when generating the makefiles
# The bug happened on master; might be ok on final releases.
RUN ln -s "$(pwd)/swift-corelibs-libdispatch/dispatch/generic/module.modulemap" "./swift-corelibs-libdispatch/dispatch/module.modulemap"
RUN ./swift/utils/build-script --preset="${SWIFT_PRESET}" installable_package="${SWIFT_ARCHIVE_OUTPUT_PATH}" install_destdir="/tmp/swift-built"



# Create the deb packages

# Let’s check the tar to only contain paths starting with "usr/" (to validate the
# strip in the mkdeb’s swiftlang recipes).
RUN test -f "${SWIFT_ARCHIVE_OUTPUT_PATH}" && ! tar tf "${SWIFT_ARCHIVE_OUTPUT_PATH}" | grep -vqE '^usr/'

WORKDIR "/tmp/swift-deb"
COPY mkdeb_swiftlang_recipe.yaml swiftlang/recipe.yaml
COPY mkdeb_swiftlang_libs_recipe.yaml swiftlang-libs/recipe.yaml
RUN mkdeb build --from "${SWIFT_ARCHIVE_OUTPUT_PATH}" --recipe "./swiftlang" --to "${SWIFTLANG_DEB_PATH}" swiftlang:${ARCH}=${SWIFT_VERSION}
RUN mkdeb build --from "${SWIFT_ARCHIVE_OUTPUT_PATH}" --recipe "./swiftlang-libs" --to "${SWIFTLANG_LIBS_DEB_PATH}" swiftlang-libs:${ARCH}=${SWIFT_VERSION}

#VOLUME "${OUTPUT_PATH}"
#CMD ["echo", "Nothing to run. You can retrieve the built products in the volume of this image."]





# Let’s build the compiler image
FROM debian:stretch-slim AS swiftlang_compiler
ARG OUTPUT_PATH=/mnt/output
LABEL maintainer="François Lamboley <francois.lamboley@happn.com>"
LABEL description="A docker image to compile a Swift project. Bind mount “${OUTPUT_PATH}” to retrieve the built project and the swiftlang-libs deb file."

# To match the previous image (did not find a way to reuse the variables…)
ARG ARCH=amd64
ARG SWIFT_BRANCH
ARG SWIFT_TAG=4.2.1-RELEASE
ENV SWIFT_TAG=${SWIFT_TAG} \
    SWIFT_BRANCH=${SWIFT_BRANCH}
ENV SWIFT_VERSION=${SWIFT_TAG}${SWIFT_BRANCH}
ENV SWIFTLANG_DEB_NAME="swiftlang_${SWIFT_VERSION}-1~mkdeb1_${ARCH}" \
    SWIFTLANG_LIBS_DEB_NAME="swiftlang-libs_${SWIFT_VERSION}-1~mkdeb1_${ARCH}"
ENV SWIFTLANG_DEB_PATH="${OUTPUT_PATH}/${SWIFTLANG_DEB_NAME}.deb" \
    SWIFTLANG_LIBS_DEB_PATH="${OUTPUT_PATH}/${SWIFTLANG_LIBS_DEB_NAME}.deb"

ENV DEBS_FOLDER="/tmp/swift_debs"
ENV OUTPUT_PATH="${OUTPUT_PATH}"

# If Swift was compiled with clang 6.0, let’s install clang 6.0 here too for
# consistency. Not sure it’s 100% needed though…
COPY debian_backports.list /etc/apt/sources.list.d/debian_backports.list
RUN apt-get update && apt-get install -y --no-install-recommends \
  clang \
# clang-6.0 \
  libblocksruntime-dev \
  libcurl3 \
  libicu57 \
  libpython2.7 \
  libxml2 \
# To clone repositories
  ca-certificates \
  git \
  ssh \
# Swift repositories that have C dependencies work better with pkg-config
  pkg-config \
&& rm -rf /var/lib/apt/lists/*
# If we installed clang-6.0 from backport, we need to install the alternatives…
#RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-6.0 1000 && \
#    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-6.0 1000 && \
#    update-alternatives --install /usr/bin/cc cc /usr/bin/clang-6.0 1000
WORKDIR "${DEBS_FOLDER}"
COPY --from=swiftlang_builder "${SWIFTLANG_DEB_PATH}" ./
COPY --from=swiftlang_builder "${SWIFTLANG_LIBS_DEB_PATH}" ./
RUN dpkg -i "./${SWIFTLANG_LIBS_DEB_NAME}.deb" "./${SWIFTLANG_DEB_NAME}.deb"

COPY "build_swift_package.sh" "/usr/local/bin/build_swift_package.sh"

WORKDIR "${OUTPUT_PATH}"
ENTRYPOINT ["build_swift_package.sh"]
