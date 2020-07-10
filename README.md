# Build and publish go-ipfs as a snap package

> https://snapcraft.io/ipfs

Snap is the default package manager for ubuntu since the release of 20.04. This repo captures what we know about building go-ipfs as a snap packge and publishing it to the snapstore. 

**WARNING** The IPFS core team do not maintain the ipfs snap (yet). The official source for go-ipfs is https://dist.ipfs.io/#go-ipfs and the recommended install path is here https://docs.ipfs.io/install/command-line-quick-start/


## Known issues

- `ipfs mount` fails as fusermount is not included in the snap, and cannot work from a snap as it is not able to create non-root mounts, see: https://github.com/elopio/ipfs-snap/issues/6

```console
ubuntu@primary:~$ ipfs mount
2020-07-10T09:54:17.458+0100	ERROR	node	node/mount_unix.go:91	error mounting: fusermount: exec: "fusermount": executable file not found in $PATH
2020-07-10T09:54:17.463+0100	ERROR	node	node/mount_unix.go:95	error mounting: fusermount: exec: "fusermount": executable file not found in $PATH
```

## Requirements

You need `snapcraft` installed locally

```console
# ubuntu or similar
$ snap install snapcraft --classic

# macos
$ brew install snapcraft
```


## Usage

**Build** out a snap package for go-ipfs by running the following from this project

```console
$ snapcraft
```

**Test** the built snap package by installing it on a system that has `snapd`

```
$ snap install ipfs_<snap details here>.snap
# then kick the tires
$ ubuntu@primary:~$ ipfs daemon
Initializing daemon...
go-ipfs version: 0.7.0-dev
```

You can test it out on mac too. By installing and using `snapcraft`, it'll pull in `multipass` which is a quick way to run an ubuntu vm, and it has a notion of a primary container, which gets nice things like automounting your home dir in the vm, so you can:

```console
# install your .snap in a multipass vm
$ multipass shell
ubuntu@primary:~$ cd ~/Home/path/to/snap/on/host/filesystem
ubuntu@primary:~$ snap install ipfs_<snap details>.snap --devmode --dangerous
ubuntu@primary:~$ ipfs daemon
Initializing daemon...
go-ipfs version: 0.7.0-dev
```

**Publish** the snap to offical snapstore will be automated by [https://snapcraft.io/build](https://snapcraft.io/build). To promote a release or edit the workflow, you'll need to create an accoung on snapcraft, then request to be added as a maintainer by opening an issue on this repo. Then you can publish from the command line by

```console
$ snapcraft upload ipfs-<snap version>.snap
```

Note, you need to login via `snapcraft login` first. You can pass a channel that you want to distribute this release to, e.g. for an rc you could do 

```console
$ snapcraft upload ipfs-0.7.0-rc1_amd64.snap --release beta
```

## Notes

### To build from source or from offical tar

The snapcraft.yml in this repo will build go-ipfs from source. This allows the snapcraft building service to compile it for different architectures. Snap also supports wrapping pre-built binaries, and a example of that is included as `snap/snapcraft-prebuilt.yaml`. 

This option is included in case we run into issues with building snaps from source, or want to ensure the packages only use official artefacts. It requires no special dockerfile, the existing `snapcore/snapcraft:stable` is sufficient to build it, as it simply copies and unpacks tar files from dist.ipfs.io for packaging.

### Versioning

Snaps have a human readable version property e.g. `0.6.0` which we would want to keep in sync with the version of ipfs that it installs. Snaps also have a automatically assigned revision number, which is a monotonically increasing integer e.g `1171`, used internally by snap to manage isolation and rollbacks. Every time you publish a release to the snapstore it is assigned a revision.

The well trodden path in snap world is to hardcode the human readable version of the snap into the snapcraft.yml `version` property. If you do that, you can use the `$SNAPCRAFT_PROJECT_VERSION` variable elsewhere in the file to avoid duplication. Howeverm it also means that we'd have to manually come and update that version to cut a release, or have ci edit and commit changes to the snapcraft.yaml file to automate it. Of note that is the path that the original author took in https://github.com/elopio/ipfs-snap/blob/b5464179f945ee0c23732442592bc14fb9779881/scripts/snap.sh#L15-L19

The other option is to use the `adopt-info` property which allows us to programatically grab the version number during the build process. See: https://snapcraft.io/docs/using-external-metadata#heading--scriptlet

The progamatic solution is enticing, but I'm currently hitting an issue where the master branch of go-ipfs is not building, and it's not clear how to set the source-tag correctly for the pull if you dont already have the source.


### Snap isolation and the ipfs repo

New versions of the same snap are isolated from each other, allowing nice things like rollback of updates. In the case of IPFS though, the peerId, pins, and all locally cached blocks are stored in the repo, and the app takes care of upgrading the repo as the format changes, so it's more useful to allow new versions of the ipfs snap to be able to re-use the same repo. This was raised as a user issue in [https://github.com/elopio/ipfs-snap/issues/12](https://github.com/elopio/ipfs-snap/issues/12). That snaps auto-update when a new release is available makes this even more of an issue. 

The prefered solution in snap world, as [pointed out by @jamiew and @mkg20001](https://github.com/elopio/ipfs-snap/issues/12) is to use the `SNAP_COMMON` dir as the `IPFS_PATH`, which creates the repo in `$HOME/snap/ipfs/common` and allows it to be re-used by all versions of the the ipfs snap. The snapcraft.yaml files in this repo contain that fix and it works as expected. The same repo is used across updates.


### Building in docker

This repo includes a Dockerfile that creates an image that can build go-ipfs from source and package it as a snap. It starts with `snapcore/snapcraft:stable` and adds in `go` and just enough tools to allow snapcraft to build go-ipfs. It is published to dockerhub as `ipfs/ipfs-snap-builder`. 

```console
$ docker run -v $(pwd):/my-snap ipfs/ipfs-snap-builder:latest sh -c "apt update && cd /my-snap && snapcraft --debug"
```

To update the Dockerfile (e.g to keep the go version provided in sync with https://github.com/ipfs/go-ipfs/blob/master/Dockerfile#L1) you need to rebuild the image, tag it, and publish it to dockerhub

```
$ docker build -t ipfs/ipfs-snap-builder --build-arg GIT_COMMIT=$(git rev-parse HEAD) .
$ docker tag ipfs/ipfs-snap-builder ipfs/ipfs-snap-builder:2.0
$ docker push ipfs/ipfs-snap-builder:2.0
$ docker push ipfs/ipfs-snap-builder:latest 
```

## Credits

Many thanks to 
- @elopio for getting `ipfs` into the snap store, and the work on https://github.com/elopio/ipfs-snap
- @bertrandfalguiere for the nudge to get it working.
- @protocol for the time to figure it out.
