#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

#
# working example functions with appropriate exit codes
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        (exit 0)

        if [[ $( whoami ) != "root" ]]; then
            str_thisFile=$( echo ${0##/*} )
            str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_thisFile'"

            # (exit 1)      # same as below
            false           # same as above
        fi
    }

# create file #
    function CreateFile
    {
        (exit 0)
        echo -en "Creating file...\t"

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # file not found
        if [[ ! -e $1 ]]; then
            touch $1 &> /dev/null || (exit 255)

        else
            (exit 3)
        fi

        case "$?" in
            0)
                echo -e "Successful."
                true;;

            3)
                echo -e "Skipped. File '$1' exists."
                true;;

            255)
                echo -e "Failed. Could not create file '$1'.";;

            254)
                echo -e "Failed. Null exception/invalid input.";;

            {3-255})
                false;;
        esac
    }

# create file #
    function DeleteFile
    {
        (exit 0)
        echo -en "Deleting file...\t"

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # file not found
        if [[ ! -e $1 ]]; then
            (exit 3)

        else
            touch $1 &> /dev/null || (exit 255)
        fi

        case "$?" in
            0)
                echo -e "Successful."
                true;;

            3)
                echo -e "Skipped. File '$1' does not exist."
                true;;

            255)
                echo -e "Failed. Could not delete file '$1'.";;

            254)
                echo -e "Failed. Null exception/invalid input.";;

            {3-255})
                false;;
        esac
    }

# write to file #
    function WriteVarToFile
    {
        (exit 0)
        echo -en "Writing to file...\t"

        # null exception
        if [[ -z $1 || -z $2 ]]; then
            (exit 254)
        fi

        # file not found exception
        if [[ ! -e $1 ]]; then
            (exit 253)
        fi

        # file not readable exception
        if [[ ! -r $1 ]]; then
            (exit 252)
        fi

        # if a given element is a string longer than one char, the var is an array #
        for str_element in ${2}; do
            if [[ ${#str_element} -gt 1 ]]; then
                bool_varIsAnArray=true
                break
            fi
        done

        if [[ "$?" -eq 0 ]]; then

            # write array to file #
            if [[ $bool_varIsAnArray == true ]]; then
                for str_element in ${2}; do
                    echo $str_element >> $1 || (exit 255)
                done

            # write string to file #
            else
                echo $2 >> $1 || (exit 255)
            fi
        fi

        case "$?" in
            0)
                echo -e "Successful."
                true;;

            255)
                echo -e "Failed.";;

            254)
                echo -e "Failed. Null exception/invalid input.";;

            253)
                echo -e "Failed. File '$1' does not exist.";;

            252)
                echo -e "Failed. File '$1' is not readable.";;

            {131-255})
                false;;
        esac
    }

    # function to comment out given lines, to be overwritten?
    # function WriteVarToFile
    # {
    #     # # NOTE: necessary for newline preservation in arrays and files #
    #     # SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    #     # IFS=$'\n'      # Change IFS to newline char

    #     # (exit 0)
    #     # echo -e "Writing to file... "

    #     # # parameters #
    #     # bool_varIsAnArray=false
    #     # str_thisFile=$1

    #     # if [[ -z $2 ]]; then
    #     #     (exit 254)
    #     # fi

    #     # echo $2

    #     # # if a given element is a string longer than one char, the var is an array #
    #     # for str_element in ${2}; do
    #     #     if [[ ${#str_element} -gt 1 ]]; then
    #     #         bool_varIsAnArray=true
    #     #         break
    #     #     fi
    #     # done

    #     # if [[ $bool_varIsAnArray == true ]]; then
    #     #     declare -ar arr_input1=($2)

    #     # else
    #     #     str_input1=$2
    #     # fi

    #     # # loop through file, check for injection points ? (of which to overwrite by the index value)

    #     # for str_line in $str_thisFile; do
    #     #     for (( int_i=0; int_i < ${#arr_input1[@]}; int_i++ )); do
    #     #         case $str_line in
    #     #             *"$int_i"
    #     #         esac
    #     #     done
    #     # done


    # }

# create backup #
    function CreateBackupFromFile
    {
        # unreserved exit codes
        # 3-125, 129, 131-255

        #
        # 3         :   safe exit, skip
        # 131-255   :   general failure
        # 254       :   specific exception
        # 253       :   ditto
        # etc.
        #


        # behavior:
        #   create a backup file
        #   return boolean, to be used by main
        #

        (exit 0)
        echo -en "Backing up file...\t"

        # parameters #
        str_thisFile=$1

        # create false match statements before work begins, to catch exceptions
        # null exception
        if [[ -z $str_thisFile ]]; then
            (exit 254)
        fi

        # file not found exception
        if [[ ! -e $str_thisFile ]]; then
            (exit 253)
        fi

        # file not readable exception
        if [[ ! -r $str_thisFile ]]; then
            (exit 252)
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
                (exit 254)
            fi

            for str_element in ${arr_thisDir[@]}; do
                if cmp -s $str_thisFile $str_element; then
                    (exit 3)
                    break
                fi
            done

            # if latest backup is same as original file, exit
            if cmp -s $str_thisFile ${arr_thisDir[-1]}; then
                (exit 3)
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
                (exit 3)
            fi

            # new parameters #
            str_line=${arr_thisDir[-1]%"${str_suffix}"}     # substitution
            str_line=${str_line##*.}                        # ditto

            # check if string is a valid integer #
            if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
                declare -i int_lastIndex="${str_line}"

            else
                (exit 254)
            fi

            (( int_lastIndex++ ))           # counter

            # source file is newer and different than backup, add to backups
            if [[ $str_thisFile -nt ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                cp $str_thisFile "${str_thisFile}.${int_lastIndex}${str_suffix}"

            elif [[ $str_thisFile -ot ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                (exit 3)

            else
                (exit 3)
            fi

        # no backups, create backup
        else
            cp $str_thisFile "${str_thisFile}.0${str_suffix}"
            # echo -e "Operation complete."
        fi

        # append output and return code
        # when declaring this function, note the return code and create a condition given if "failure" (failure or just skipping) is mission critical.
        case "$?" in
            0)
                echo -e "Successful."
                true;;

            3)
                echo -e "Skipped. No changes from most recent backup."
                true;;

            255)
                echo -e "Failed.";;

            254)
                echo -e "Failed. Exception: Null/invalid input.";;

            253)
                echo -e "Failed. Exception: File '$str_thisFile' does not exist.";;

            252)
                echo -e "Failed. Exception: File '$str_thisFile' is not readable.";;

            {131-255})
                false;;

            # NOTES:
                # be more specific with exit codes?
                #   the idea is to have *absolute* exit codes (0 or 255) for pass and fail.
                #   and to have *relative* exit codes (any num between 0 and 255) for specific errors and exceptions
                #       then, output the string to console here (save space writing the same error, per function, per condition statement)
                #       finally, override those at the end of a given function, with exit '255'
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
        echo -en "Testing Internet connection...\t"
        ping -q -c 1 8.8.8.8 &> /dev/null && echo -e "Successful." || ( echo -e "Failed." && (exit 255) )          # set exit status, but still execute rest of function

        echo -en "Testing connection to DNS...\t"
        ping -q -c 1 www.google.com &> /dev/null && echo -e "Successful." || ( echo -e "Failed." && (exit 255) )   # ditto

        case "$?" in
            0)
                true;;

            *)
                echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
                false;;
        esac
    }

# vfio #
    function ParseIOMMUandPCI
    {
        (exit 254)
        echo -en "Parsing IOMMU groups...\t"

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
        for str_line1 in $( find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V ); do
            (exit 0)

            # parameters #
            str_thisIOMMU=$( basename $str_line1 )

            # parse given IOMMU group for PCI IDs #
            for str_line2 in $( ls ${str_line1}/devices ); do

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

        # prioritize worst exit code (place last)
        case true in
            $bool_missingDriver)
                (exit 3);;

            $bool_foundVFIO)
                (exit 254);;
        esac

        case "$?" in
                # function never failed
                0)
                    echo -e "Successful."
                    true;;

                3)
                    echo -e "Successful. One or more external PCI device(s) missing drivers."
                    true;;

                255)
                    echo -e "Failed.";;

                254)
                    echo -e "Failed. Exception: No devices found.";;

                253)
                    echo -e "Failed. Exception: Existing VFIO setup found.";;

                # function failed at a given point, inform user
                {131-255})
                    false;;
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

    echo '$? == '"'$?'"

    CheckIfUserIsRoot
    echo '$? == '"'$?'"
    echo

    TestNetwork
    echo '$? == '"'$?'"
    echo

    # file test
    str_thisFile="test.txt"
    echo '$str_thisFile == '"'$str_thisFile'"
    cat $str_thisFile
    echo

    # # check if file does NOT exist
    # if [[ ! -e $str_thisFile ]]; then        #
    # # if [[ -z $str_thisFile ]]; then            # these two statements are NOT equal
    #     touch $str_thisFile
    # fi

    # change file
    # echo -e "hello\nworld" > $str_thisFile
    # echo -e "shalom\nworld" > $str_thisFile
    # echo -e "save the\nworld" > $str_thisFile
    # echo -e "screw the\nworld" > $str_thisFile

    CreateBackupFromFile $str_thisFile
    echo '$? == '"'$?'"
    echo

    # if CreateBackupFromFile $str_thisFile; then
    #     echo -e "Pass."

    # else
    #     echo -e "Fail."
    # fi

    # declare -a arr1=({1..5})

    # echo ${!arr1[@]}

    ParseIOMMUandPCI
    echo '$? == '"'$?'"
    echo

    DeleteFile "example.txt"
    CreateFile "example.txt"
    WriteVarToFile "example.txt" "hello world"

    # DeleteFile "example.txt"

    echo -e "Exiting."