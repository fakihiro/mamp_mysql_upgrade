# ================================================================
# MAMP MySQL Upgrade Script
#
# ================================================================
#!/bin/bash

(
  _MAC_VERSION=$(sw_vers | grep ProductVersion | awk '{print $2}' | awk -F . '{print $1"."$2}')

  # El Capitan(10.11), Yosemite(10.10), Mavericks(10.9)
  #_MYSQL57_FILE="mysql-5.7.10-osx10.10-x86_64"
  _MYSQL57_FILE="mysql-5.7.13-osx${_MAC_VERSION}-x86_64"
  _MYSQL57_FILE_EXT="${_MYSQL57_FILE}.tar.gz"
  _MYSQL57_DL_URL="http://dev.mysql.com/get/Downloads/MySQL-5.7/"
  _DOWNLOAD_PATH="${HOME}/Downloads/"

  _MAMP_PATH="/Applications/MAMP/"

  echo "Check the MySQL Version."
  echo $(${_MAMP_PATH}Library/bin/mysql --version)
  while :;do
    echo -n "Upgrade ? [y/n] : "
    read ans
    case ${ans} in
      y) break
      ;;
      n) exit 0
      ;;
      *)
      ;;
    esac 
  done

  if [ ! -f ${_DOWNLOAD_PATH}${_MYSQL57_FILE} ];then
    if [ ! -f ${_DOWNLOAD_PATH}${_MYSQL57_FILE_EXT} ];then
      echo "Download the MySQL \"${_MYSQL57_FILE_EXT}\" to ${_DOWNLOAD_PATH}"
      ( cd ${_DOWNLOAD_PATH} && curl -# -L -O ${_MYSQL57_DL_URL}${_MYSQL57_FILE_EXT} )
      echo ""
    fi
    echo "Now thawing..."
    (cd ${_DOWNLOAD_PATH} && tar zxvf ${_DOWNLOAD_PATH}${_MYSQL57_FILE_EXT})
    echo ""
  fi

  echo "Stop the MAMP."
  nohup ${_MAMP_PATH}bin/stopMysql.sh > /dev/null 2>&1
  sudo ${_MAMP_PATH}bin/stopApache.sh
  echo -n "Please wait"
  while :;do
    [ $(ps aux | grep mysqld | grep -v "grep" | wc -l) -eq 0 ] && [ $(ps aux | grep httpd | grep -v "grep" | wc -l) -eq 0 ] && break
    echo -n "." && sleep 1
  done
  echo " >> done."
  echo ""

  _ORIGINAL_EXT=".before_mysqlupgrade"
  _BACKUP_DIR=(\
    "${_MAMP_PATH}Library/bin" \
    "${_MAMP_PATH}Library/share"\
    "${_MAMP_PATH}bin"\
  )
  for x in ${_BACKUP_DIR[*]};do
    if [ ! -e ${x}${_ORIGINAL_EXT} ];then
      echo "Back up the ${x} to ${x}${_ORIGINAL_EXT}"
      rsync -arv --progress ${x}/* ${x}${_ORIGINAL_EXT}
      chmod 775 ${x}${_ORIGINAL_EXT}
    fi
  done

  _EXCLUDES=("--exclude=mysqld_multi" "--exclude=mysqld_safe" "--exclude=mysql_config")
  echo "Copy ${_MAMP_PATH}Library/bin"
  rsync -arv --progress ${_DOWNLOAD_PATH}${_MYSQL57_FILE}/bin/* ${_MAMP_PATH}Library/bin/ ${_EXCLUDES[@]}

  echo "Copy ${_MAMP_PATH}Library/share"
  rsync -arv --progress ${_DOWNLOAD_PATH}${_MYSQL57_FILE}/share/* ${_MAMP_PATH}Library/share/

  _tmp=$(cat ${_MAMP_PATH}bin/startMysql.sh | sed "s#--socket=\(.*\).sock#--socket=/tmp/mysql.sock#") && echo "${_tmp}" > ${_MAMP_PATH}bin/startMysql.sh
  _tmp=$(cat ${_MAMP_PATH}bin/stopMysql.sh | sed "s#--socket=\(.*\).sock#--socket=/tmp/mysql.sock#") && echo "${_tmp}" > ${_MAMP_PATH}bin/stopMysql.sh

  echo "Start MySQL."
  nohup ${_MAMP_PATH}bin/startMysql.sh > /dev/null 2>&1
  echo -n "Please wait"
  while :;do
    [ $(ps aux | grep mysqld | grep -v "grep" | wc -l) -ne 0 ] && break
    echo -n "." && sleep 1
  done
  echo " OK."

  echo "Migrate to new version."
  echo "${_MAMP_PATH}Library/bin/mysql_upgrade -u root -p -h 127.0.0.1"
  echo "Please type root password."
  ${_MAMP_PATH}Library/bin/mysql_upgrade -u root -p -h 127.0.0.1

  echo ">> Upgrade Success OK!!"
)
