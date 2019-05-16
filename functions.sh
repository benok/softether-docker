# get latest repository form github
get_latest() {
  curl --silent https://api.github.com/repos/$1/releases/latest |
  grep '"tag_name":' |
  sed -E 's/.*"([^"]+)".*/\1/'
}

# get gids of groups
get_gid() {
  for grp in ${1//,/ }; do
    g=$(getent group adm)
    g=( ${g//:/ } )
    echo -n "${g[2]} "
  done
}

get_host_dir_groups() {
  for v in ${1//,/ }; do 
     vol=( ${v//:/ } )
     host_dir=${vol[0]}
     cont_dir=${vol[1]}
     perms=( $(stat -c "%a" $host_dir | grep -o .) )
     # in case there are no full permissions, we get a group
     if [ ${perms[2]} != 6 -a ${perms[2]} != 7 ]; then
       if [ -e $host_dir ]; then
	 # todo check version of stat
         if stat --printf="%g " . >/dev/null 2>&1; then 
	   gid=$(stat --printf="%g " $host_dir)
         else
	   gid=$(stat -f "%g " $host_dir)
         fi
	 # output only non-root groups
	 if [ $gid != 0 ]; then
	   echo -n $gid
	 fi
       fi
     fi
  done
}

merge_unique_int() {
  declare -a merged=( "${!1}" "${!2}" "${!3}" ${!4} )
  merged=( $(printf '%s\n' ${merged[@]} | sort -un) )
  echo "${merged[@]}"
}
