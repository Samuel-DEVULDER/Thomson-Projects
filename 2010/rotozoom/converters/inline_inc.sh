#!/bin/sh

oldIFS=$IFS
IFS=$'\n'
main=$1
file=$2
for line in $(cat $file)
do
	case $line in
		\(main\)*)
			arg=`echo $line |cut -d')' -f2-|cut -d' ' -f1`
			if [ "$main" != "." ]
			then
				echo "(main)$main"
				main="."
			fi
		;;
		\(include\)*)
			arg=`echo $line |cut -d')' -f2-|cut -d' ' -f1`
			file=$arg
			echo 1>&2 "including $file..."
			sh $0 $main $file 
		;;
		*) 
			echo $line
		;;
	esac
done
IFS=$oldIFS
