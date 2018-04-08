#!/usr/bin/env bash
mpr=">>"
version="1.2"
task="build"
url=""
out="$PWD/mod"
recursion=true
usage="Usage: mkmod <git repo URI>
Arguments:
-b <branch>  - choose the branch to clone.
-t <gradle task>  - choose the gradle task to execute, default is 'build'.
-h  - display the help message.
-o <path>  - specify the mod artifacts output directory, default is <working dir>/mod.
-nr  - disable recursive cloning, enabled by default."

exitAndClear() {
    if [ -n ${dir} ]
        then
        echo "$mpr Cleaning the '$dir' directory..."
        rm -rf ${dir}
    fi
    exit $1
}






# Parse Args
IFS=' '; args=($@); unset IFS;
for ((i=0; i<${#args}; i++))
do
  param=${args[i]}
  case ${param} in
    -b) branch=${args[i + 1]}; ((i++));;
    -t) task=${args[i + 1]}; ((i++));;
    -o) out=${args[i + 1]}; ((i++));;
    -h) echo "$usage"; exit 0;;
    -nr) recursion=false;;
    *)
      if [ -z "$url" ]
        then
        url=${param}
      fi
      ;;
  esac
done

if [ -z "$url" ]
  then
  echo "$mpr You haven't set the git repository URI!
$usage"
  exit 1
fi

# Create the temp directory
cmd="mktemp -d -t mkmod.XXXXXXXX"
dir=$(${cmd})
if [ $? -ne 0 ]
  then
  echo "$mpr The '$cmd' command exited with a non-zero exit code"
  exit $?
elif [ -z "$dir" ]
  then
  echo "$mpr The '$cmd' command returned an empty string."
  exit 1
fi

# Build the clone cmd and print the message
cmd="git clone $url $dir"
printBranch="*default*"
if [ -n "$branch" ]
  then
  cmd+=" -b $branch"
  printBranch=${branch}
fi
if ${recursion}
  then
  cmd+=" --recursive"
fi

echo "[mkmod $version]
--URL: $url
--Out: $out
--Branch: $printBranch
--Task: $task
--Recursive cloning: $recursion"

# Clone the repo
if ! eval ${cmd}
  then
  echo "$mpr The '$cmd' command exited with a non-zero exit code."
  exitAndClear 1;
fi

# Detect the Gradle executable
echo "$mpr Detecting the gradle executable..."
if [ -e "$dir/gradlew" ]
  then
  cmd="$dir/gradlew"
else
  cmd="gradle"
fi
cmd+=" $task"

#Build the mod
echo "$mpr Building the mod using the '$cmd' command..."
if ! (cd ${dir}; eval ${cmd})
  then
  echo "$mpr !!!WARNING!!! The '$cmd' command exited with a non-zero exit code, skipping..."
fi

dirLibs=${dir}/build/libs
echo "$mpr Copying the '$dirLibs' directory into the '$out' directory..."
cp -r "$dirLibs" "$out"

exitAndClear 0