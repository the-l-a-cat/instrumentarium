#!/bin/sh

# ---------------------------------------------------------------------------- #
#                                                                              #
#     Agava Dedicated/Colocation Instrumentarium toolset.                      #
#                                                                              #
#     Since we keep a few host properties in our custom mib, it may be         #
#     wise to make a script to access them more easily.                        #
#                                                                              #
# ---------------------------------------------------------------------------- #

. $(dirname "$0")/global.sh

my_snmpget ()
{
    # Takes a host and a list of snmp oid arguments.
    my_host="$1"
    shift

    case $my_snmp_version in
        (1)
            snmpget -Ovq -v1 -c $my_snmp_1_community "$my_host" $* \
                2> /dev/null
            return $?
            ;;
        (*)
            echo "SNMP version $my_snmp_version is not supported." > \
                /dev/stderr
            return 1
            ;;
    esac
}

my_output ()
{
    if test $glob_csv
    then
        echo -n "${1#*=}\t"
    else
        echo "$1"
    fi
}

if test $# -eq 0 || test "$1" = -h || test "$1" = --help
then
    echo "USAGE: snmp-filter.sh [-h|--help]
           snmp-filter.sh [-c|--csv] CHECK [CHECK..]

    where CHECK is one of 

    hostname os php named nginx raid mta panel mysql-server_socket
    machine-architecture operating-system version-major version-full jail_path
    default_ip snmp_version

        -c : Makes the output a tab-separated csv.
    "
    exit 0
fi

if test "$1" = "-c" || test "$1" = "--csv"
then
    glob_csv=on
    shift
fi
    
 
requested_check=" $*"


########## Print headers. ########## 
if test $glob_csv
then

    my_output "server_id"
    while read check_type check_id check_name
    do
        requested_check_instance="$requested_check"
        while test "$requested_check_instance"
        do
            if test "${requested_check_instance##* }" = "$check_name" ||
                test "$requested_check" = " all"
            then
                check_output=$check_name
                my_output "$check_name=$check_output"
                break
            fi
            requested_check_instance="${requested_check_instance% *}"
        done

    done < $(dirname "$0")/snmp-filter.cfg
echo
fi


########## Print actual values. ##########

while read srv_id srv_addr
do
    my_output "server_id=$srv_id"
    if $my_ping $srv_addr >/dev/null 2>/dev/null
    then
        while read check_type check_id check_name
        do
            requested_check_instance="$requested_check"
            # echo $requested_check_instance
            while test "$requested_check_instance"
            do
                # echo $requested_check_instance
                # echo test "${requested_check_instance##* }" = "$check_name"
                if test "${requested_check_instance##* }" = "$check_name" || 
                    test "$requested_check" = " all"
                then
                    check_output=`
                        my_snmpget $srv_addr \
                            UCD-SNMP-MIB::${check_type}Output.$check_id`
                    my_output "$check_name=$check_output"
                    break
                fi
                requested_check_instance="${requested_check_instance% *}"
            done

        done < $(dirname "$0")/snmp-filter.cfg
    else
        echo "Host is down!" >/dev/stderr
    fi

    echo
done

