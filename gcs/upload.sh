#!/bin/bash
opt_n=10
opt_p=metacloud
opt_t=4

while getopts "n:p:t:" flag; do
  case $flag in
    n) opt_n="$OPTARG";;
    p) opt_p="$OPTARG";;
    t) opt_t="$OPTARG";;
    *) opt_o="NO";;
  esac
done

shift $((OPTIND-1))

num=$opt_n
project="$opt_p$(date +%Y%m%d%H%M)"
threads=$opt_t

host=$(hostname)
start_timestamp=$(date +%s)

process_log=/home/upload-${host}.log
logpath=$process_log

process_name=python

upload() {
  local i=$1
  local log_path=/home/upload-${start_timestamp}-${i}.log

  local start="u${i}-${project}-${host}-0-$(date +%s%N)"
  sudo echo $start >> $process_log && logger $start &

  sudo time gsutil cp /home/upload.mkv gs://xxx/${project}/${host}/${i}-$(date +%s).mkv >/dev/null 2>&1

  local end="u${i}-${project}-${host}-1-$(date +%s%N)"
  sudo echo $end >> $process_log && logger $end &
}

check() {
  local process_min_threads=$1
  local count=0
  sleep 3
  while true; do
    local num_threads=$(ps -e -T -f | grep "${process_name}" | grep -v "grep" | wc -l)

    if [ ${num_threads} = ${process_min_threads} ]; then
      if [ -f "${logpath}" ]; then
        gsutil cp $logpath gs://xxx/xxx/${project}/upload-${host}-${start_timestamp}.log >/dev/null 2>&1
        sudo rm -rf /home/*.log
        echo "FINISHED::upload results already pushed to bucket"
        break
      else
        echo "File does not exists."
        count=$[$count+1]
        [ $count = 3 ] && break
      fi
    fi

    sleep 1
  done
}

check ${threads} &

for i in $(seq 1 1 ${num}); do
  upload ${i} &
done &
