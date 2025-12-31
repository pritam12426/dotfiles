#!/bin/bash

set -e

file="$1"

file=$(realpath "$file")

path=$(dirname "$file")
filename=$(basename "$file")
file_without_extension="${filename%.*}"

run_command=""

# Checking file type and setting up the run command
case "$file" in
*.c)
	# run_command+="$CC -std=c17 $file -fsanitize=address "
	run_command+="$CC -std=c17 $file "
	;;
*.cpp)
	run_command+="$CXX -std=c++20 $file "
	;;
*.rs)
	run_command+="cargo run "
	;;
*.pl)
	run_command+="perl $file "
	;;
*/[Mm]akefile)
	run_command+="make -C $path -f $file "
	;;
*/CMakeLists.txt)
	LIB="${PWD##*/}"
	BUILD_DIR="$path/build-arm64"
	# run_command+="source '$CPP_LIB_DIR/env'; "
	run_command+="cmake -S '$path' -B '$BUILD_DIR' "

	if [ ! -d "$BUILD_DIR" ]; then
		run_command+="-DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_INSTALL_PREFIX='$CPP_LIB_DIR/$LIB' "
	fi

	;;
*.html)
	run_command+="open $file "
	;;
*.d2)
	first_line=$(head -n 1 "$file")

	if [[ $first_line == \#!* ]]; then
		run_command+="${first_line:2} $file "
	else
		run_command+="d2 --watch --layout elk --center $file "
	fi

	;;
*.cal)
	run_command+="bc -liqf $file "
	;;
*.py)
	run_command+="python3 $file "
	;;
*.lua)
	run_command+="lua $file "
	;;
*.go)
	run_command+="go run $file "
	;;
*.zig)
	run_command+="zig run $file "
	;;
*.sql)
	run_command+="sqlite3 -header -table -bail -nullvalue '-null-' $path/$file_without_extension.sqlite3 < $file "
	# run_command+="sqlite3 -header -table -bail -nullvalue \"\u{F9E2}\" < $file "
	;;
*.cs)
	run_command+="dotnet run "
	;;
*.java)
	run_command+="java $file "
	;;
*.js)
	run_command+="node $file "
	;;
*.ts)
	run_command+="node $file "
	;;
*.sh | *.bash | *.zsh)
	# run_command+="bash -x $file "
	run_command+="bash $file "
	;;
*)
	$file
	;;
esac

RUN=0

if [[ ! $run_command =~ ^/usr/bin/clang ]]; then
	echo "$run_command" >&2; printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
	eval "$run_command"
	exit $?
fi

if [[ "$2" == '-' ]]; then
	RUN=1
	TMPDIR="$path/"
	shift 1
fi

run_command+="-pedantic -Wall -arch arm64 $2 $3 $4 $5 $6 $7 $8 $9 -o '$TMPDIR${filename//./-}.out'"

# Execute the run command
echo "$run_command" >&2; printf '%*s\n' "$(tput cols)" '' | tr ' ' '-' >&2
eval "$run_command"
return_code=$!

if [[ $RUN == 1 ]]; then
	exit $return_code
fi

# Run the compiled output if compilation was successful
if [[ $? -eq 0 ]]; then
	strip "$TMPDIR${filename//./-}.out"
	# /usr/bin/time -h "$TMPDIR${filename//./-}.out"
	"$TMPDIR${filename//./-}.out"
fi

exit $?
