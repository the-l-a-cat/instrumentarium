#! /bin/sh


# kin @ agava Tue 18 Mar 2014
# Nevermind the "sheep"!

. $(dirname "$0")/global.sh

my_barn=`mktemp -d`
my_cmdname=loop
my_forklimit=32


usage () {
    cat >&2 << EOF
    Usage: `basename $0` [ -s ] [ -c ] COMMAND ...
        -s  Suppress decoration.  
        -c  Output one line of stdout in CSV format.
        -e  Evaluate COMMAND before executing it through SSH.
    stdin: Tab-separated list of form INT-KEY MASTER-IP-ADDR
EOF
    exit
}


while getopts ces VARNAME
do
    # Arguments should precede the command to be run, so break on "?".
    case $VARNAME in
        (s) my_be_silent=yes ; shift ;;
        (c) my_csv=yes ; shift ;;
        (e) my_evaluate=yes ; shift ;;
        (?) break ;;
    esac
done


test $# -eq 0 && usage

my_cmd="$*"


# From stdin!
while read sheep_number sheep_master
do
    i=$(( i+1 )) # Iteration counter.
    u=$(( u+1 )) # Launched processes counter.
    i_str=` printf "%.4u" $i ` # String representation of the iteration counter.

    (
    sheep_master_name=` dig @$my_ns_server +short -x $sheep_master | sed 's/\.$//' `
    # A sheep's name is derived from its master PTR record.

    sheep_home=$my_barn/$i_str$sheep_master_name

    mkdir -p $sheep_home

    echo -n $sheep_master_name > $sheep_home/sheep_master_name
    echo -n $sheep_number > $sheep_home/sheep_number

    if test $my_evaluate
    then
        my_cmd=`eval $my_cmd`
    fi

    echo "$my_cmd" | tee $sheep_home/$my_cmdname.in |
    eval $my_ssh $sheep_master_name 1> $sheep_home/$my_cmdname.out 2> $sheep_home/$my_cmdname.err

    if test -z $my_be_silent
    then
        echo -n . >&2
    fi

    ) &

    if test $u -gt $my_forklimit
    then
        wait
        u=0
        if test -z $my_be_silent
        then
            echo -n \  >&2
        fi
    fi

done

wait 
if test -z $my_be_silent
then
    echo -n \\n >&2
fi


if test -z $my_csv
then

    for sheep_home in  $my_barn/*
    do
        for kind in out err
        do
            if test -s $sheep_home/$my_cmdname.$kind
            then
                if test -z $my_be_silent
                then
                    echo "==== Sheep `cat $sheep_home/sheep_master_name` says to std$kind:" >&2
                fi
                cat $sheep_home/$my_cmdname.$kind
            fi
        done
    done

else

    for sheep_home in  $my_barn/*
    do
        cat $sheep_home/sheep_number
        echo -n \\t
        cat $sheep_home/$my_cmdname.out | tr \\n \\t
        echo -n \\n
    done

fi

rm -rf $my_barn

