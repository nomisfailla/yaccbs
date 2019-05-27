#!/usr/bin/env bash

clean_some() {
    rm -rf build-gcc
    rm -rf build-binutils
    rm -rf $binutils_loc
    rm -rf $gcc_loc
}

clean_all() {
    clean_some
    rm -f $gcc_tar
    rm -f $binutils_tar
}

default_binutils_version="2.32"
default_gcc_version="9.1.0"
default_target="i686-elf"

echo "            yaccbs            "
echo "[ yet another cross compiler ]"
echo "[        build script        ]"
echo "                              "

echo "gcc version [$default_gcc_version]"
read -p '> ' gcc_version
gcc_version=${gcc_version:-$default_gcc_version}
echo "using gcc $gcc_version"
echo ""

echo "binutils version [$default_binutils_version]"
read -p '> ' binutils_version
binutils_version=${binutils_version:-$default_binutils_version}
echo "using binutils $binutils_version"
echo ""

echo "target [$default_target]"
read -p '> ' target
target=${target:-$default_target}
echo "targeting $target"
echo ""

export PREFIX="$HOME/opt/$target-cross"
export TARGET=$target
export PATH="$PREFIX/bin:$PATH"

echo "building gcc $gcc_version and binutils $binutils_version for $target"
echo "building into $PREFIX"

binutils_loc="binutils-$binutils_version"
binutils_tar="$binutils_loc.tar.xz"

echo "downloading $binutils_tar"
echo ""
if ! curl https://ftp.gnu.org/gnu/binutils/$binutils_tar -f --output $binutils_tar ; then
    echo ""
    echo "[error] could not find binutils version $binutils_version"
    exit 1
fi
echo ""

gcc_loc="gcc-$gcc_version"
gcc_tar="$gcc_loc.tar.xz"

echo "downloading $gcc_tar"
echo ""
if ! curl https://ftp.gnu.org/gnu/gcc/gcc-$gcc_version/$gcc_tar -f --output $gcc_tar ; then
    echo ""
    echo "[error] could not find gcc version $gcc_version"
    exit 1
fi
echo ""

echo "extracting $binutils_tar"
tar xf $binutils_tar
echo ""

echo "extracting $gcc_tar"
tar xf $gcc_tar
echo ""

mkdir build-binutils
cd build-binutils
../$binutils_loc/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
if ! make ; then
    echo ""
    echo "[error] failed to build binutils"
    clean_some
    exit 1
fi
if ! make install ; then
    echo ""
    echo "[error] failed to install binutils"
    clean_some
    exit 1
fi

cd ..

mkdir build-gcc
cd build-gcc
../$gcc_loc/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
if ! make all-gcc ; then
    echo ""
    echo "[error] failed to build gcc"
    clean_some
    exit 1
fi
if ! make all-target-libgcc ; then
    echo ""
    echo "[error] failed to build libgcc"
    clean_some
    exit 1
fi
if ! make install-gcc ; then
    echo ""
    echo "[error] failed to install gcc"
    clean_some
    exit 1
fi
if ! make install-target-libgcc ; then
    echo ""
    echo "[error] failed to install libgcc"
    clean_some
    exit 1
fi

cd ..

echo ""
echo "cleaning up..."
clean_all

echo ""
echo "build complete"
echo "'$PREFIX'"
echo "thank you for using yaccbs"
echo ""
