#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ $(whoami) != "root" ]]; then
            str_thisFile=$(echo ${0##/*})
            str_thisFile=$(echo $str_thisFile | cut -d '/' -f2)
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'bash $str_thisFile'\n\tor\n\t'su' and 'bash $str_thisFile'. Exiting."
            exit 1
        fi
    }

# create backup #
    function CreateBackupFromFile
    {

        # behavior:
        #   create a backup file
        #   return boolean, to be used by main
        #

        (exit 0)
        echo -en "Backing up file... "

        # parameters #
        str_thisFile=$1

        # create false match statements before work begins, to catch exceptions
        # null exception
        if [[ -z $str_thisFile ]]; then
            # echo -e "Exception: Input is null. Operation skipped."
            (exit 255)
        fi

        # file not found exception
        if [[ ! -e $str_thisFile ]]; then
            # echo -e "Exception: '$str_thisFile' does not exist. Operation skipped."
            (exit 255)
        fi

        # file not readable exception
        if [[ ! -r $str_thisFile ]]; then
            # echo -e "Exception: '$str_thisFile' is not readable. Operation skipped."
            (exit 255)
        fi

        # work #
        # parameters #
        declare -r str_suffix=".old"
        declare -r str_thisDir=$( dirname $1 )
        declare -ar arr_thisDir=( $( ls -1v $str_thisDir | grep $str_thisFile | grep $str_suffix | uniq ) )

        # positive non-zero count
        if [[ "${#arr_thisDir[@]}" -ge 1 ]]; then

            # parameters #
            declare -ir int_maxCount=5
            str_line=${arr_thisDir[0]}
            str_line=${str_line%"${str_suffix}"}        # substitution
            str_line=${str_line##*.}                    # ditto

            # check if string is a valid integer #
            if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
                declare -ir int_firstIndex="${str_line}"

            else
                # echo -e "Exception: '$str_line' is not an integer. Operation skipped."
                (exit 255)
            fi

            # # debug #
            # echo
            # echo -e "'$int_firstIndex'"

            for str_element in ${arr_thisDir[@]}; do
                if cmp -s $str_thisFile $str_element; then
                    # echo -e "'$str_thisFile' is same as backup(s). Operation skipped."
                    (exit 100)
                    break
                fi
            done

            # if latest backup is same as original file, exit
            if cmp -s $str_thisFile ${arr_thisDir[-1]}; then
                # echo -e "'$str_thisFile' is same as backup(s). Operation skipped."
                (exit 100)
            fi

            # before backup, delete all but some number of backup files
            while [[ ${#arr_thisDir[@]} -ge $int_maxCount ]]; do
                if [[ -e ${arr_thisDir[0]} ]]; then
                    rm ${arr_thisDir[0]}
                    break
                fi
            done

            # if *first* backup is same as original file, exit
            if cmp -s $str_thisFile ${arr_thisDir[0]}; then
                # echo -e "'$str_thisFile' is same as backup(s). Operation skipped."
                (exit 100)
            fi

            # new parameters #
            str_line=${arr_thisDir[-1]%"${str_suffix}"}     # substitution
            str_line=${str_line##*.}                        # ditto

            # check if string is a valid integer #
            if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
                declare -i int_lastIndex="${str_line}"

            else
                # echo -e "Exception: '$str_line' is not an integer. Operation skipped."
                (exit 255)
            fi

            # echo -e "'$int_lastIndex'"      # debug #
            (( int_lastIndex++ ))           # counter
            # echo -e "'$int_lastIndex'"      # debug #

            # source file is newer and different than backup, add to backups
            if [[ $str_thisFile -nt ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                cp $str_thisFile "${str_thisFile}.${int_lastIndex}${str_suffix}"
                # echo -e "'$str_thisFile' is newer than backup(s). Operation complete."
                # (exit 0)

            elif [[ $str_thisFile -ot ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                # echo -e "'$str_thisFile' is older than backup(s). Operation skipped."
                (exit 100)

            else
                # echo -e "'$str_thisFile' is same as backup(s). Operation skipped."
                (exit 100)
            fi

        # no backups, create backup
        else
            cp $str_thisFile "${str_thisFile}.0${str_suffix}"
            # echo -e "Operation complete."
            # (exit 0)
        fi

        # append output and return code
        # when declaring this function, note the return code and create a condition given if "failure" (failure or just skipping) is mission critical.
            case "$?" in
                0)
                    echo -e "Complete."
                    return true;;

                255)
                    echo -e "Failed. Thrown exception."
                    return false;;

                *)
                    echo -e "Skipped."
                    return false;;

                # NOTES:
                    # be more specific with exit codes?
                    #   the idea is to have *absolute* exit codes (0 or 255) for pass and fail.
                    #   and to have *relative* exit codes (any num between 0 and 255) for specific errors and exceptions
                    #       then, output the string to console here (save space writing the same error, per function, per condition statement)
                    #       finally, override those at the end of a given function, with exit '255'

                # 100)
                #     echo -e "Skipped.";;

                # *)
                #     echo -e "Unknown status. Exit code not described.";;
            esac
    }

# conditional execution #
    function TestNetwork
    {
        # behavior:
        #   test internet connection and DNS servers
        #   return boolean, to be used by main
        #

        (exit 0)    # set exit status to "successful" before work starts

        # test IP resolution
        echo -en "Testing Internet connection...\t\t"
        ping -q -c 1 8.8.8.8 >> /dev/null && echo -e "Successful." || echo -e "Failure." && (exit 255)          # set exit status, but still execute rest of function

        echo -en "Testing connection to DNS...\t"
        ping -q -c 1 www.google.com >> /dev/null && echo -e "Successful." || echo -e "Failure." && (exit 255)   # ditto

        case "$?" in

            # function never failed
            0)
                return true;;

            # function failed at a given point, inform user
            255)
                echo -e "Check network settings and try again."
                return false;;
        esac
    }

# vfio #
    function ParseIOMMUandPCI
    {
        (exit 0)
        echo -en "Parsing IOMMU groups... "

        # parameters #
        declare -ir int_lastIOMMU="$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )"
        declare -a arr_DeviceIOMMU=()
        declare -a arr_DevicePCI_ID=()
        declare -a arr_DeviceDriver=()
        declare -a arr_DeviceName=()
        declare -a arr_DeviceType=()
        declare -a arr_DeviceVendor=()
        bool_missingDriver=false
        bool_foundVFIO=false

        # parse list of IOMMU groups #
        for str_line1 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

            # parameters #
            str_thisIOMMU=$( basename $str_line1 )

            # parse given IOMMU group for PCI IDs #
            for str_line2 in $( ls ${str_line1}/devices ); do
                (exit 1)

                # parameters #
                # save output of given device #
                str_thisDevicePCI_ID="${str_line2##"0000:"}"
                str_thisDeviceName="$( lspci -ms ${str_line2} | cut -d '"' -f6 )"
                str_thisDeviceType="$( lspci -ms ${str_line2} | cut -d '"' -f2 )"
                str_thisDeviceVendor="$( lspci -ms ${str_line2} | cut -d '"' -f4 )"
                str_thisDeviceDriver="$( lspci -ks ${str_line2} | grep driver | cut -d ':' -f2 )"

                if [[ -z $str_thisDeviceDriver ]]; then
                    str_thisDeviceDriver="N/A"
                    bool_missingDriver=true

                else
                    if [[ $str_thisDeviceDriver == *"vfio-pci"* ]]; then
                        str_thisDeviceDriver="N/A"
                        bool_foundVFIO=true

                    else
                        str_thisDeviceDriver="${str_thisDeviceDriver##" "}"
                    fi
                fi

                # parameters #
                arr_DeviceIOMMU+=( "$str_thisIOMMU" )
                arr_DevicePCI_ID+=( "$str_thisDevicePCI_ID" )
                arr_DeviceDriver+=( "$str_thisDeviceDriver" )
                arr_DeviceName+=( "$str_thisDeviceName" )
                arr_DeviceType+=( "$str_thisDeviceType" )
                arr_DeviceVendor+=( "$str_thisDeviceVendor" )
            done
        done

        case true in
            $bool_foundVFIO)
                (exit 255)
                ;;

            $bool_missingDriver)
                (exit 100)
                ;;

            *)
                (exit 0)
                ;;
        esac

        case "$?" in
            # function never failed
            0)
                echo -e "Complete."
                # return true
                ;;

            # function failed at a given point, inform user
            255)
                echo -e "Failed. Existing VFIO setup detected."
                # return false
                ;;

            # missed targets
            *)
                echo -e "Complete. One or more device driver is missing."
                # return false
                ;;
        esac
    }

# scratch #
    function main {

        echo filename
        echo $0

        echo present working directory
        echo
        pwd
        basename $( pwd )   echo *lowest* child directory

        # parse files in current dir #
        echo
        ls $( pwd )

        # file test
        str_thisFile="test.txt"

        # check if file does NOT exist
        if [[ ! -e $str_thisFile ]]; then        #
        # if [[ -z $str_thisFile ]]; then            # these two statements are NOT equal
            touch $str_thisFile

            #echo -e "hello\nworld" > $str_thisFile
        fi

        # check if file exists
        if [[ -e $str_thisFile ]]; then
            cat $str_thisFile
        fi

        # check if file is readable #
        echo
        if [[ -e $str_thisFile ]]; then
            cat $str_thisFile
        fi

    }

# main #
    CheckIfUserIsRoot

    # file test
    str_thisFile="test.txt"

    # check if file does NOT exist
    if [[ ! -e $str_thisFile ]]; then        #
    # if [[ -z $str_thisFile ]]; then            # these two statements are NOT equal
        touch $str_thisFile
    fi

    # echo -e "hello\nworld" > $str_thisFile
    # echo -e "shalom\nworld" > $str_thisFile
    # echo -e "save the\nworld" > $str_thisFile
    # echo -e "screw the\nworld" > $str_thisFile

    # CreateBackupFromFile $str_thisFile


    # if CreateBackupFromFile $str_thisFile; then
    #     echo -e "Pass."

    # else
    #     echo -e "Fail."
    # fi

    # echo "'$?'" # exit code from last function

    declare -a arr1=({1..5})

    echo ${!arr1[@]}

    ParseIOMMUandPCI

    echo $?
