#! /bin/sh


# kin @ agava Tue 18 Mar 2014


my_ns_server=ns1.agava.net
my_forklimit=32


# From stdin!
while read sheep_master
do
    i=$(( i+1 )) # Iteration counter.
    u=$(( u+1 )) # Launched processes counter.
    i_str=` printf "%.4u" $i ` # String representation of the iteration counter.

    (
    sheep_master_name=` dig @$my_ns_server +short -x $sheep_master | sed 's/\.$//' `
    # A sheep's name is derived from its master PTR record.

    echo -n $sheep_master
    echo -n \\t
    echo -n $sheep_master_name
    echo

    ) &

    if test $u -gt $my_forklimit
    then
        wait
        u=0
    fi

done

wait 
