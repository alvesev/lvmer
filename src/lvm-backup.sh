#!/bin/bash

#
#  Copyright 2011-2012 Alex Vesev
#
#  This file is part of LVMER.
#
#  LVMER is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  LVMER is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with LVMER.  If not, see <http://www.gnu.org/licenses/>.
#
##

#  LVMER is a tool to assist with LVM volumes routine operations.
#
##


declare -r groupVolumes="host_main_group"
declare -r volumeLogicalOrigin="host_root"
declare -r volumeLogicalSpare="host_root_spare"

function initLVM {
    local    devOrigin="/dev/sdaX"
    local    devSpare="/dev/sdaX"

    pvcreate "${devSpare}"
    vgextend "${devSpare}"
    vgextend "${groupVolumes}" "${devSpare}"
}

function printLVMFreeExtents {
    local -i freeExtents=0

    freeExtents="$( vgdisplay "${groupVolumes}" \
                | egrep "Free([[:space:]]*)PE([[:space:]]*)/([[:space:]]*)Size([[:space:]]*)" \
                | awk '{print $5}' )"
    echo -n "${freeExtents}"
}

function createBackup {
    local -i freeExtents=0

    freeExtents="$( printLVMFreeExtents )"
    lvcreate --extents "${freeExtents}" --snapshot /dev/"${groupVolumes}"/"${volumeLogicalOrigin}" --name "${volumeLogicalSpare}"
}

function restoreFromBackup {
    lvconvert --merge /dev/"${groupVolumes}"/"${volumeLogicalSpare}"
}

function dropBackup {
    lvremove /dev/"${groupVolumes}"/"${volumeLogicalSpare}"
}

function showDoc {
echo "
This is LVMER. It is a tool to assist with LVM volumes routine operations.

USAGE IS

    $( basename "${0}" ) options

OPTIONS

    --create-spare  -  Create spare volume.

    --drop-spare  -  Remove backup volume.

    --restore  -  Restore from spare volume: merge spare into origin.

    --help  -  Show some documentation.

COPYRIGHT AND LICENCE

Copyright © 2011-2012 Alex Vesev. License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.

This is free software: you are free to change and redistribute it. There is NO WARRANTY, to the extent permitted by law.
"
}


# # #
 # #
# #
 #
#

[ ${UID} != 0 ] \
    && echo "ERROR:${0}:${LINENO}: This script is run NOT as root. Bailing out." >&2 \
    && errorState=${errorMisc}

[ ${#} == 0 ] \
    && showDoc \
    && exit ${errorMisc}
routineName=""
while [ ${#} != 0 ] ; do
    argumentName="${1#--}" # Strip leading '--'.
    argumentName="${argumentName%%=*}" # Strip trailing '=*'
    argumentValue="${1#*=}" # Strip leading '*='.
    case "${argumentName}" in
    help)
        showDoc
        exit ${errorState}
    ;;

# Actions

    create-spare)
        [ -z "${routineName}" ] \
            && routineName="${argumentName}"
    ;;
    drop-spare)
        [ -z "${routineName}" ] \
            && routineName="${argumentName}"
    ;;
    restore)
        [ -z "${routineName}" ] \
            && routineName="${argumentName}"
    ;;

# Options

    attribute)
            [ -z "${attributeValue}" ] \
                && attributeValue="${argumentValue:-SOME_VALUE}"
        break
    ;;
    *)
        echo "ERROR:${0}:${LINENO}: Unknown argument name '${argumentName}'." >&2
        exit ${errorMisc}
    ;;
    esac
    shift 1
done

case "${routineName}" in
create-spare)
    createBackup
;;
drop-spare)
    dropBackup
;;
restore)
    restoreFromBackup
;;
*)
    echo "ERROR:${0}:${LINENO}: Unknown routine name '${routineName}'." >&2
    exit ${errorMisc}
;;
esac

exit ${errorEpic}
