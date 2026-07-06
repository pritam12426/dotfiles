#!/bin/sh

if [ "$#" -lt 2 ]; then
	echo "Usage: clanginit <c|c-min|cxx|wx|c++|ard|typ|wx> <project-name>"
	exit 1
fi

[ -z "$DOT_FILE" ] && {
	echo "DOT_FILE not set"
	exit 1
}

lower_input=$(echo "$1" | tr '[:upper:]' '[:lower:]')

case "$lower_input" in
	c)
		cp -rvp "$DOT_FILE/../global/c-cpp-template/c" "$2"
		;;
	c-min)
		cp -rvp "$DOT_FILE/../global/c-cpp-template/c_min_with_make" "$2"
		;;
	c++ | cxx)
		cp -rvp "$DOT_FILE/../global/c-cpp-template/c++" "$2"
		;;
	wx)
		cp -rvp "$DOT_FILE/../global/c-cpp-template/wx-form-template" "$2"
		;;
	ard)
		cp -rvp "$DOT_FILE/../global/embedded/arduino-cli-uno/" "$2" &&
			mv "$2/arduino-cli-uno.ino" "$2/$2.ino"
		;;
	typ)
		cp -rvp "$DOT_FILE/../global/typst/" "$2" &&
			mkdir -pv "$2/assets"
		;;
	*)
		echo "Unsupported: <c cxx c++ ard typ wx>: $1"
		exit 1
		;;
esac


case "$lower_input" in
	c | cxx | c++ | wx)
		echo ""
		cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/src/CmakeConfig.h.in"  "$2/src/CmakeConfig.h.in"
		cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/zed/"                  "$2/.zed"
		cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/CMakePresets.json"     "$2/CMakePresets.json"
		cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/clangd.yml"            "$2/.clangd"
		;;
esac

# All common files
printf "\nCommon project boiler code files:\n"
cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/TODO.txt"        "$2/TODO.txt"
cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/REFERENCES.md"   "$2/REFERENCES.md"
cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/README.md"       "$2/README.md"
cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/clang-tidy.yml"  "$2/.clang-tidy"
cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/gitattributes"   "$2/.gitattributes"
cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/gitignore"       "$2/.gitignore"


case "$lower_input" in
	c | cxx | c++ | wx)
		printf "Do you want to have doxygen in this project '%s' ?  (y/n): " "$2"
		read -r REPLY
		case "$REPLY" in
			[Yy]*)
				cp -rvp "$DOT_FILE/../global/c-cpp-template/common_template/doc" "$2/doc/" &&
					[ -f "$2/CMakeLists.txt" ] && cat "$2/doc/patch.txt" >> "$2/CMakeLists.txt" &&
						rm -f "$2/doc/patch.txt"
				;;
		esac
esac
