#!/bin/sh

# ---------------------------------------------------------------------------- #
#                                                                              #
#     Agava Dedicated/Colocation Instrumentarium toolset.                      #
#                                                                              #
#     Classify hosts as belonging to a certain category                        #
#     based on an SSH command's output.                                        #
#                                                                              #
# ---------------------------------------------------------------------------- #

. $(dirname "$0")/global.sh

my_temp=`mktemp -d`
my_forklimit=32

if test $# -eq 0
then
    echo "USAGE: categorize.sh COMMAND

Effect: Classify hosts based on the output of the COMMAND you specify.
Output: A number of files named like CATEGORY.source in the current directory.

Example:
% eternal_truth.sh | categorize.sh uname -s
% ls
Linux.source FreeBSD.source 
"
    exit 0
fi

command="$*"


while read ID ADDR
do
    u=$((u+1))

    (
        if $my_ping $ADDR >/dev/null 2>/dev/null
        then
            category="$($my_ssh $ADDR $command)"
            echo "$ID\t$ADDR\t$category" \
                > $my_temp/$ID.category
            echo -n '.'
        else
            echo -n '!'
        fi
    ) &

    if test $u -ge $my_forklimit
    then
        wait
        u=0
        echo -n ' '
    fi
done
wait
echo

find $my_temp -type f -name '*.category' |
    xargs cat |
    while read ID ADDR CATEGORY
    do
        echo "$ID\t$ADDR" >> $CATEGORY.source
    done

find $my_temp -delete


