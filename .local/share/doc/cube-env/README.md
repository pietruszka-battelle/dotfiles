# CUBE Environment Tooling

Tools used to do stuff in CUBEs

## Prerequisites

Install `yq`

```sh
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update
sudo apt install yq -y
```

By default `pip` will install executables in `$HOME/.local/bin` directory, creating if needed.  If you didn't have that directory before, you may need to source your `.profile`

```sh
source ~/.profile
```

Or just ensure that `yq` is in your `PATH`

## Hacking on the tools

This project uses a fairly standard [GNU Autotools] build.  If you're not
familiar with Automake and the like definitely review the docs if you plan to
contribute to this project.

- https://www.gnu.org/software/automake/manual/html_node/index.html

### Install gnu toolchain


#### Ubuntu/Debian (including Windows w/WSL)

```
sudo apt install build-essential autoconf automake
```

#### install `gengetoptions` parser generator

CUBE tooling uses `gengetoptions` from [getoptions](https://github.com/ko1nksm/getoptions) for
argument parsing and expects the parser generator to be in you `PATH`

```sh
git clone https://github.com/ko1nksm/getoptions.git
cd getoptions
make
make install PREFIX=$HOME/.local
```

### Bootstrapping the build

There are a lot of opinions on building with
autotools, these are Sandman's.  Feel free to ignore them and build the project
using your own autotools practices.

From the project root

```sh
./bootstrap.sh
```

`bootstrap` will generate all the scripts needed to configure the build.  The
`--prefix` dir defaults to $PWD--handy for testing the build.

### Using the build

*Remember to ALWAYS run `make ...` from the same directory you ran
`./configure`*

Once you have the build configured, run it is just the normal make stuff.  Just
remember to work from the created build directory.

```sh
cd build
make install
```

For local builds like this the only extra we need to do is source the hook file

```sh
. ./etc/profile.d/cube-env-hook.sh
```

If it worked you should see the message "Hooking into the CUBE"

### Distribution

There are a number of ways to distribute projects using Autotools, it's one of
the perks.  The easiest is using `dist`

```sh
make dist
```

You should see some archives in the project root, usually a tarball and a zip.
This can be changed in `configure.ac`. Before you really release you should test
the distribution.  Again, Autotools makes this really easy.

```sh
make distcheck
```

This will ensure that your distribution passes all the standard checks.  For
example, in this project Autotools is configured to ensure all executables
provide `--help` and `--version`.

#### Release

WIP: basically goes something like this

```sh
# run release script
./release

# do all the things it says to do, then...
cd deb_repo/
git add .
git commit -m"$(head -n1 ../debian/changelog)"
git push

# after GH Action completes, test with
sudo apt update
apt show cube-env
```
