#!/bin/sh

# ---------------------------------------------------------------------------- #
#                                                                              #
#     Agava Dedicated/Colocation Instrumentarium toolset.                      #
#                                                                              #
#     This is a simple configuration management tool. In essence,              #
#     all it does is upload a few files on some remote systems and             #
#     run a small post-install script on each.                                 #
#                                                                              #
# ---------------------------------------------------------------------------- #

# kin @ agava Mon 24 Mar 2014
# V2 kin @ agava Mon 06 May 2014
# Purpose: Upload certain prepared filesystem trees.

. $(dirname "$0")/global.sh

my_valid_name_characters='[-a-zA-Z0-9_/]'
# my_valid_name_characters='[-a-zA-Z0-9_]'

my_forklimit=32

# Takes CONFIGURATION and COMMAND as mandatory arguments, and COMMAND must be a function.
f_forks ()
{
    # echo entering f_forks >/dev/stderr
    CONFIGURATION=$1
    if ! test -f $CONFIGURATION.source
    then
        echo "$CONFIGURATION.source must exist!" > /dev/stderr
        exit 1
    fi
    COMMAND="$2"

    shift 2
    ARGS="$@"

    while read ID IP
    do
        export ID
        u=$(( u+1 ))
        (
            $COMMAND $CONFIGURATION $IP $ARGS
        ) &

        if test $u -ge $my_forklimit
        then
            wait
            u=0
            echo -n ' '
        fi
    done < $CONFIGURATION.source
    wait
    echo
}

f_remote_install ()
{
    # echo entering f_remote_install >/dev/stderr
    IP=$2
    if ! $my_ping $IP >/dev/null 2>/dev/null
    then
        return 1
    fi

    CONFIGURATION=$1
    if test -z $CONFIGURATION
    then
        echo \
            "Internal error: no CONFIGURATION supplied to a loop function." \
            > /dev/stderr
        exit 1
    fi

    shift 2 

    
    unset flag_same_tar

    if test -f $CONFIGURATION.tar
    then
        # We would like to check if the same tar file was once unpacked.
        checksum=`cat $CONFIGURATION.tar | md5sum`
        remote_checksum=`$my_ssh $IP test -f \
            /etc/minister-checksum \&\& cat /etc/minister-checksum`
        if test "$remote_checksum" = "$checksum"
        then
            flag_same_tar=1 # Do nothing.
        fi

        if test -z $flag_same_tar
        then
            # This will overwrite all and everything as easy as a puff.
            $my_ssh $IP sudo tar -U -C / -x -f- \; echo -n $checksum \| sudo \
                tee /etc/minister-checksum \> /dev/null < $CONFIGURATION.tar

            # We would also like to do some post-processing, but only afterwards.
            if test -f $CONFIGURATION.post_proc.sh
            then 
                # Yes I understand this is quite a strange way to transfer
                # environment. Can you think of a better?
                echo ID="$ID"                              |
                cat - $CONFIGURATION.post_proc.sh          |
                eval $my_ssh $IP > /dev/null
            fi
        fi
    fi
    echo -n '.'

} 

f_create ()
{
    # echo entering f_create >/dev/stderr
    CONFIGURATION=$1

    if ! test -d $CONFIGURATION
    then
        echo "Directory $CONFIGURATION must exist!" > /dev/stderr
        exit 1
    fi

    sudo tar -C $CONFIGURATION -pcf $CONFIGURATION.tar .  
}

f_upload ()
{
    # echo entering f_upload >/dev/stderr
    CONFIGURATION=$1

    if ! test -f $CONFIGURATION.tar
    then
        echo "File $CONFIGURATION.tar must be created first!" > /dev/stderr
        exit 1
    fi

    if ! test -f $CONFIGURATION.source
    then
        echo "File $CONFIGURATION.source must be created first!" > /dev/stderr
        exit 1
    fi

    f_forks $CONFIGURATION f_remote_install 
}

f_validate ()
{
    # echo entering f_validate >/dev/stderr
    if test -z "$1"
    then return 1
    else
        VAR="$1"
        if
            # ! test "$VAR" = `printf %q "$VAR"` # Not portable nuff.
            test -n "`
                while
                    test "$VAR" != "${VAR#$my_valid_name_characters}"
                do
                    VAR="${VAR#$my_valid_name_characters}"
                done && echo $VAR `"

        then return 1
        fi
    fi
    return 0
}


f_help ()
{
    # echo entering f_help >/dev/stderr
    echo "Usage: minister.sh [-c CONFIGURATION] [-d CONFIGURATION] [-u CONFIGURATION]
    By a CONFIGURATION I mean
    1. A file hierarchy ./CONFIGURATION/ 
    2. A csv file ./CONFIGURATION.source of form HOST_ID HOST_ADDRESS
    3. A script ./CONFIGURATION.post_proc.sh
    
    -c : Transform the file hierarchy into a tarball ./CONFIGURATION.tar.
    -d : Destroy the file hierarchy on all target hosts listed in the csv file.
    -u : Do the following:
        o Upload the tarball ./CONFIGURATION.tar to each of the target hosts
        o Unpack it in / as root 
        o execute ./CONFIGURATION.post_proc.sh on each of the target hosts as root.
    " > /dev/stderr
    exit 1
}


if test $# -lt 2
then
    f_help
fi

while getopts c:d:u: VARNAME
do
    if ! f_validate "$OPTARG"
    then
        echo "Invalid option: $OPTARG" > /dev/stderr
        exit 1
    fi

    case $VARNAME in
        (c) # For "create me a tarball from a directory".
            f_create $OPTARG
            ;;
        (d) # For "attempt to erase the hierarchy from target hosts".
            f_erase $OPTARG
            ;;
        (u) # For "upload a tarball and unpack it in the root, then process post-install."
            f_upload $OPTARG
            ;; 
        (*) # Misinvocation.
            f_help
            ;;
    esac
done


