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

#
    function CreateAndAppendBackupFromFile {

        # behavior:
        #   create latest backup from file (do not save first-time backup)
        #   if file does not exist or is not readable, throw exception
        #   else, continue
        #   if backup exists, check if source file is newer, and create new backup with increment
        #       else, do nothing
        #   else, create backup
        #

        # NOTE: nested if statements are *slow*, and confusing

        # parameters #
        str_thisFile=$1

        # create false match statements before work begins, to catch exceptions
            # null exception
            if [[ -z $str_thisFile ]]; then
                echo -e "Exception: Input is null. Exiting."
                exit 255
            fi

            # file not found exception
            if [[ ! -e $str_thisFile ]]; then
                echo -e "Exception: '$str_thisFile' does not exist. Exiting."
                exit 255
            fi

            # file not readable exception
            if [[ ! -r $str_thisFile ]]; then
                echo -e "Exception: '$str_thisFile' is not readable. Exiting."
                exit 255
            fi

            # one way of creating a backup file
            # create only one backup file
                # parameters #
                # str_oldFile1="$1.old"

                # # backup exists
                # if [[ -e $str_oldFile1 ]]; then

                #     # no changes
                #     if [[ $str_thisFile -ef $str_oldFile1 ]]; then
                #         echo -e "'$str_thisFile' has no changes from backup. Exiting."
                #         exit 0
                #     fi

                #     # source file is newer than backup
                #     if [[ $str_thisFile -nt $str_oldFile1 ]]; then
                #         cp $str_thisFile $str_oldFile1

                #     # source file is older than backup file, save newer backup file as "new" and create new backup as "old"
                #     else

                #         mv $str_oldFile $str_newFile
                #         cp $str_thisFile $str_oldFile
                #         echo -e "WARNING: '$str_thisFile' is older than backup."
                #     fi

                # # create backup
                # else
                #    cp $str_thisFile $str_oldFile1
                # fi

            # another way of creating a backup file(s)
            # create up to five backup files
                # parameters #
                str_oldFile1="$1.old"
                str_thisDir1=$( dirname $1 )
                declare -ar arr1=( $( ls $str_thisDir1 | grep -E $str_oldFile1 | uniq ) )

                # positive non-zero count
                if [[ ${#arr_thisDir1[@]} -gt 0 ]]; then

                    if [[ ${#arr_thisDir1[@]} -eq 1 ]]; then

                        # no changes
                        if [[ $str_thisFile -ef ${arr_thisDir1[1]} ]]; then
                            echo -e "'$str_thisFile' has no changes from backup. Exiting."
                            exit 0
                        fi

                        # source file is newer than backup
                        if [[ $str_thisFile -nt ${arr_thisDir1[1] }]; then
                            cp $str_thisFile $str_oldFile1

                        # source file is older than backup file, save newer backup file as "new" and create new backup as "old"
                        else

                            mv ${arr_thisDir1[1]} $str_oldFile1"00"$
                            cp $str_thisFile ${arr_thisDir1[1]}
                            echo -e "WARNING: '$str_thisFile' is older than backup."
                        fi

                    else

                        # limit five backup files
                        if [[ ${#arr1[@]} -gt 5 ]]; then
                            declare -ir int_count=5

                        else
                            declare -ir int_count=${#arr1[@]}
                        fi

                        # parse array in reverse sort, rename each file with a new three-digit integer
                        for (( int_i=$int_count ; int_i>1 ; i-- )); do

                            # parameters #
                            str_file1=${arr1[$int_i]}
                            # str_file2=${{str_file1}%%*${int_i}}    # one way of returning new value
                            (( int_i++ ))

                            # suffix is a three digit value
                            case *"${int_i}"* in
                                {1..9})
                                    str1="00${int_i}"
                                    ;;

                                # {10..99})                          # not necessary due to limit of five backup files
                                #     str1="0${int_i}"
                                #     ;;

                                # {100..999})
                                #     str1="${int_i}"
                                #     ;;

                                # *)
                                #     echo -e "THAT'S A HUGE BITCH."
                                #     exit 255
                                #     ;;
                            esac

                            # update file #
                            # str_file2+=$str1                        # ditto; one way
                            str_file2="${str_oldFile1}${str1}"        # another way of returning new value
                            mv ${str_file1} ${str_file2}

                            (( int_i-- ))
                        done

                        #
                        cp $str_thisFile $str_oldFile1"001"
                    fi

                # no backups, create backup
                else
                    cp $str_thisFile $str_oldFile1"001"
                fi
    }

# echo filename
echo $0

# echo present working directory
echo
pwd
basename $( pwd )   # echo *lowest* child directory

# parse files in current dir #
echo
ls $( pwd )

# file test
str_thisFile="test.txt"

# check if file does NOT exist
if [[ ! -e $str_thisFile ]]; then        #
# if [[ -z $str_thisFile ]]; then            # these two statements are NOT equal
    touch $str_thisFile

    echo -e "hello\nworld" > $str_thisFile
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
















