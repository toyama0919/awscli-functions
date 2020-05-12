if [ "$(uname)" = "Linux" ]; then
  READLINK_PATH=$(which readlink)
elif [ "$(uname)" = "Darwin" ]; then
  READLINK_PATH=$(which greadlink)
fi

if [ "$0" = "bash" ] || [ "$0" = "-bash" ]; then
  current_file=$($READLINK_PATH -f ${BASH_SOURCE[0]})
else
  current_file=$($READLINK_PATH -f $0)
fi

dir=$(dirname $current_file)
for f in $(find $dir/functions -type f)
do
  source $f
done
