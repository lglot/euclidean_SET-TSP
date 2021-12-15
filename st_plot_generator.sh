#!/bin/bash

if test ! $1
then
        echo Inserisci numero nodi; exit 1;
fi

if test ! -f set_tsp.ecl
then
        echo File eclipse non trovato; exit 1;
fi


command='eclipse.exe -f $instance -f ../../set_tsp.ecl -f $file_op -e "set_tsp(\"$output_file\")"'
file_op="../../nocrossing_clockwise.ecl"
cd instances-clustered
for dir in *
do
	if test -d $dir && test ${dir:8:2} -le $1
	then
		if test ! -d ../plot_result/$dir
		then
			mkdir -p ../plot_result/$dir
		fi
		cd $dir
		for instance in *.d.pl
		do
			output_file=../../plot_result/$dir/`echo $instance | cut -f 1 -d .`
			if test ! -f $output_file
			then
				printf "TSP per instaza $instance\n"
				eval $command > /dev/null

					if test $? -ne 0 
					then
						echo "Esecuzione eclipse fallita"
						exit 1
					fi

			else
				echo "Soluzione già trovata per istanza $istance"
			fi
		done
		cd .. 
	fi
done
cd .. 

