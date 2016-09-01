#! /bin/bash
#
# ShaderC
# compiling GLSL shader code into SPIR-V
# 
# compile this with ./apothecary -a 64 update shaderc
#
# uses a CMake build system

FORMULA_TYPES=( "vs" "linux64")

# define the version by sha
VER=c63df792b2d535734cd0d1e6111de7ca29dcb555

# tools for git use
GIT_URL=https://github.com/google/shaderc
GIT_TAG=$VER

# download the source code and unpack it into LIB_NAME
function download() {
	curl -Lk $GIT_URL/archive/$GIT_TAG.tar.gz -o shaderc-$GIT_TAG.tar.gz
	tar -xf shaderc-$GIT_TAG.tar.gz
	mv shaderc-$GIT_TAG shaderc
	rm shaderc*.tar.gz
}

# prepare the build environment, executed inside the lib src dir
function prepare() {
	pushd third_party
	# git clone https://github.com/google/googletest.git
	git clone https://github.com/google/glslang.git
	git clone https://github.com/KhronosGroup/SPIRV-Tools.git spirv-tools
	git clone https://github.com/KhronosGroup/SPIRV-Headers.git spirv-tools/external/spirv-headers
	popd
}

# executed inside the lib src dir
function build() {
	rm -f CMakeCache.txt

	if [ "$TYPE" == "vs" ] ; then
		if [ $ARCH == 32 ] ; then
			mkdir -p build_vs_32
			cd build_vs_32
			cmake .. -G "Visual Studio 14 Win32" -Dgtest_disable_pthreads=ON -DSHADERC_SKIP_TESTS=ON -DSHADERC_ENABLE_SHARED_CRT=ON
			vs-build "shaderc.sln" Build "Release|386" 
		elif [ $ARCH == 64 ] ; then
			mkdir -p build_vs_64
			cd build_vs_64
			cmake .. -G "Visual Studio 14 Win64" -Dgtest_disable_pthreads=ON -DSHADERC_SKIP_TESTS=ON -DSHADERC_ENABLE_SHARED_CRT=ON
			vs-build "shaderc.sln" Build "Release|x64"
			vs-build "shaderc.sln" Build "Debug|x64"
		fi
	else
        if [ $CROSSCOMPILING -eq 1 ]; then
            source ../../${TYPE}_configure.sh
            EXTRA_CONFIG=" "
        else
            EXTRA_CONFIG=" "
        fi
		# *nix build system

		mkdir -p build 
		cd build

		cmake .. -Dgtest_disable_pthreads=ON -DSHADERC_SKIP_TESTS=ON -DSHADERC_ENABLE_SHARED_CRT=ON
		cmake --build . --config Debug -- -j$PARALLEL_MAKE
		# cmake --build . --config Release -- -j$PARALLEL_MAKE

	fi
}

# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {
	# prepare headers directory if needed
	mkdir -p $1/include/shaderc

	# prepare libs directory if needed
	mkdir -p $1/lib/$TYPE

	if [ "$TYPE" == "vs" ] ; then
		cp -Rv libshaderc/include/* $1/include
		if [ $ARCH == 32 ] ; then
			mkdir -p $1/lib/$TYPE/Win32
			cp -v build_vs_32/libshaderc/Release/shaderc_combined.lib $1/lib/$TYPE/Win32/shaderc_combined.lib
		elif [ $ARCH == 64 ] ; then
			mkdir -p $1/lib/$TYPE/x64
			cp -v build_vs_64/libshaderc/Release/shaderc_combined.lib $1/lib/$TYPE/x64/shaderc_combined.lib
			cp -v build_vs_64/libshaderc/Debug/shaderc_combined.lib $1/lib/$TYPE/x64/shaderc_combinedd.lib
		fi		
	else
		pwd
		# Standard *nix style copy.
		# copy headers
		cp -Rv libshaderc/include/* $1/include
		# copy lib
		cp -Rv build/libshaderc/libshaderc_combined.a $1/lib/$TYPE/shaderc_combined.a
		# cp -Rv build/libshaderc/libshaderc_combinedd.a $1/lib/$TYPE/shaderc_combinedd.a
	fi

	# copy license file
	rm -rf $1/license # remove any older files if exists
	mkdir -p $1/license
	cp -v LICENSE $1/license/
}

# executed inside the lib src dir
function clean() {
	if [ "$TYPE" == "vs" ] ; then
		rm -f *.lib
	elif [ "$TYPE" == "linux64" ]; then
		#statements
		
		cmake --clean .
	else
		make clean
	fi
}
