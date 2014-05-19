#!/bin/sh


# ---------------------------------------------------------------------------- #
#                                                                              #
#     Agava Dedicated/Colocation Instrumentarium toolset.                      #
#                                                                              #
#     Gain access to the administrative database and collect server            #
#     parameters outta there.                                                  #
#                                                                              #
# ---------------------------------------------------------------------------- #

. $(dirname "$0")/global.sh

while getopts r: VARNAME
do
    case $VARNAME in

        (r) # Select some random servers.
            my_random="$OPTARG" 
            shift ;;

        (?) # Panic.
            break ;;
    esac
done

if test -n "$my_db_use_ssh"
then 
    connect="$my_ssh $my_db_ssh_channel $my_db_ssh_invocation"
else
    connect="$my_db_ssh_invocation"
fi

echo "$my_db_command" |
eval $connect |
if test -n "$my_random"
then
    sort -R |
    head -n$my_random
else
    cat
fi
