# ymd_cd: jump to directory, considering history
#
# Copyright 2015 Hiroyuki Yamada
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################

# 1. Install:
# Write in ~/.bashrc (or other your shell config file)
#
# if [ -e /path/to/ymd_cd.sh ]; then
#   source /path/to/ymd_cd.sh
# fi
#
#
# 2. Usage:
# y foo
#  -> If 'cd foo' fail, then the command search (partially-)matched directory from database
#
# y =
#  -> Show database, which is composed of "integer,directory_name"
#
# y -d bar
#  -> Delete "bar" from database. "bar" should be full path.
#
# y -c num
#  -> Clear database, except directories which still exist and it's arrival count are greater than "num".
#     When no num is specified, num is assumed as 0. (Only non exist directories are deleted.)
#
#
# 3. Database
# Shell variable YMD_CD_DATABASE, whose default value is "$HOME/.ymd_cd.db"
# It is sort before using.
#
#
# 4. Optional
# Periodical manual backup of database is highly recommended
#

declare YMD_CD_DATABASE="$HOME/.ymd_cd.db"

function y()
{
    case "$1" in
	"=" ) # show stack
	    local -a YMD_CD_STACK
	    local i=0
	    while read -r line
	    do
		YMD_CD_STACK+=("${line}")
		local m=$i
		while [ $m -gt 0 ] && [ ${YMD_CD_STACK[$m]%%\,*} -gt ${YMD_CD_STACK[$(( $m - 1 ))]%%\,*} ]; do
		    local j=$(( $m - 1 ))
		    local tmp="${YMD_CD_STACK[$m]}"
		    YMD_CD_STACK[$m]="${YMD_CD_STACK[$j]}"
		    YMD_CD_STACK[$j]="${tmp}"
		    m=$(( $m - 1 ))
		done
		i=$(( $i + 1 ))
	    done < "${YMD_CD_DATABASE}"
	    local str=""
	    for e in "${YMD_CD_STACK[@]}"
	    do
	    	str+="${e}\n"
	    done
	    echo -en "$str" > "${YMD_CD_DATABASE}"
	    cat "${YMD_CD_DATABASE}"
	    return 0
	    ;;
	'-d' )
	    if [ $# -lt 2 ] ; then
		return 1
	    fi
	    local found=0
	    local str=""
	    while read -r line
	    do
		if [ -z ${line} ]; then
		    break
		fi
		if [ ${found} -eq 0 ] && [ "${line#*\,}" = "$2"  ]; then
		    found=1
		else
		    str+="${line}\n"
		fi
	    done < ${YMD_CD_DATABASE}
	    echo -en "${str}" > "${YMD_CD_DATABASE}"
	    return 0
	    ;;
	'-c' ) # clear up database. non exsist directory and less thanthreshold arrival directory will be removed.
	    local threshold=0
	    if [ $# -ge 2 ] ; then
		if [ "$2" -gt 0 >/dev/null 2>&1 ] ; then
		    threshold=$2
		fi
	    fi
	    local str=""
	    while read -r line
	    do
		if [ -z ${line} ]; then
		    break
		fi
		if [ -d "${line#*\,}" ] && [ ${line%%\,*} -gt ${threshold}  ]; then
		    str+="${line}\n"
		fi
	    done < ${YMD_CD_DATABASE}
	    echo -en "${str}" > "${YMD_CD_DATABASE}"
	    return 0
	    ;;
	* ) # cd or jump
	    cd "$1" > /dev/null 2>&1
	    if [ $? -eq 0 ]; then
		## success cd, update data base
		local found=0
		local str=""
		while read -r line
		do
		    if [ -z ${line} ]; then
			break
		    fi
		    if [ ${found} -eq 0 ] && [ "${line#*\,}" = "${PWD}"  ]; then
			str+="$(( ${line%%\,*} + 1 )),${PWD}\n"
			found=1
		    else
			str+="${line}\n"
		    fi
		done < ${YMD_CD_DATABASE}
		if [ ${found} -eq 0 ]; then
		    str+="1,${PWD}\n"
		fi
		echo -en "${str}" > "${YMD_CD_DATABASE}"
	    else
		## sort data base
		local -a YMD_CD_STACK
		local i=0
		while read -r line
		do
		    YMD_CD_STACK+=("${line}")
		    local m=$i
		    while [ $m -gt 0 ] && [ ${YMD_CD_STACK[$m]%%\,*} -gt ${YMD_CD_STACK[$(( $m - 1 ))]%%\,*} ]; do
			local j=$(( $m - 1 ))
			local tmp="${YMD_CD_STACK[$m]}"
			YMD_CD_STACK[$m]="${YMD_CD_STACK[$j]}"
			YMD_CD_STACK[$j]="${tmp}"
			m=$(( $m - 1 ))
		    done
		    i=$(( $i + 1 ))
		done < "${YMD_CD_DATABASE}"

		## search
		local str=""
		local jumped=0
		for e in "${YMD_CD_STACK[@]}"
		do
		    if [ ${jumped} -eq 0 ]; then
			case "${e##*\/}" in
			    *"$1"* )
				cd "${e#*\,}" > /dev/null 2>&1
				str+="$(( ${e%%\,*} + 1 )),${PWD}\n"
				jumped=1
				;;
			    * )
				str+="${e}\n"
				;;
			esac
		    else
			str+="${e}\n"
		    fi
		done < "${YMD_CD_DATABASE}"

		if [ ${jumped} -eq 1 ]; then
		    echo -en "${str}" > "${YMD_CD_DATABASE}"
		    return 0
		else
		    echo "ymd_cd: $1: No such file or directory"
		    return 1
		fi
	    fi
	    ;;
    esac
}

if [ ! -e "${YMD_CD_DATABASE}" ]; then
    touch "${YMD_CD_DATABASE}"
fi
