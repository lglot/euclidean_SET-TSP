#!/bin/bash

where eclipse

if test $? -ne 0 
	then
		eclipseCmd="eclipse.exe"
	else eclipseCmd="eclipse" 
	fi

command0='$eclipseCmd -f $instance -f ../../performance_test/set_tsp_no_optimization.ecl -e "set_tsp" |
		grep -e "numero_backtracking" -e "Succ" -e "Pred" -e "time" |
		cut -f 2 -d : | tr -d $"\r" | tr -d " "'
command='$eclipseCmd -f $instance -f ../../performance_test/set_tsp_with_choice.ecl -e "set_tsp($ch1,$ch2,$ch3)" |
		grep -e "numero_backtracking" -e "Succ" -e "Pred" -e "time" |  	
		cut -f 2 -d : | tr -d $"\r" | tr -d " "'

#nchoices=3;
# eclipseExec(){
# 	choice=$(printf "%.choices${n}d" `echo "obase=2;(($1+4*$2))" | bc`)
# 	for i in $(seq 1 $nchoices)
# 	do
# 		eval ch${i}=${choice:((${i}-1)):1}
# 	done
# 	out=($(eval $command))
# 	space=" "
# 	echo "${choice}${space}${out[@]}"
# }


# four_eclipseExec(){
# 	if [$1 -ge 4]
# 	then 
# 		; wait
# 		echo ""
# 	else
# 		(out=($(eclipseExec $1 $2))) & ( out2=( $(four_eclipseExec (($1 + 1)) ) ) ) 
# 		echo "$out:$out2"
# 	fi
# }

if test $# -ne 2
then
        printf "Uso: RUNME Ni Nf\nNi: Numero nodi istanza iniziale\nNf: numero nodi istanza finale\n"; exit 1;
fi

command0='eclipse.exe -f $instance -f ../../performance_test/set_tsp_no_optimization.ecl -e "set_tsp" |
		grep -e "numero_backtracking" -e "Succ" -e "Pred" -e "time" |
		cut -f 2 -d : | tr -d $"\r" | tr -d " "'
command='eclipse.exe -f $instance -f ../../performance_test/set_tsp_with_choice.ecl -e "set_tsp($ch1,$ch2,$ch3)" |
		grep -e "numero_backtracking" -e "Succ" -e "Pred" -e "time" |  	
		cut -f 2 -d : | tr -d $"\r" | tr -d " "'

now=$(date +'%F_%H%M')
mkdir $now

output_back=$now/output_back.csv
output_time=$now/output_time.csv
output_sol=$now/output_sol.csv

nchoices=3;
sep=";"
#Ch1 = Clockwise(C)
#Ch2 = NoCrossing(N)
#Ch3 = Sort(S)
echo "sep=$sep" | tee $output_back | tee $output_time > $output_sol
header="istance;000:None;001:S,010:N,011:NS,100:C,101:CS,110;CN,111:CNS\n"	
printf "$header" >> $output_back
printf "$header" >> $output_time
printf "$header" >> $output_sol


cd ../instances-clustered
for dir in *
do
	if test -d $dir && test ${dir:8:2} -le $2 && test ${dir:8:2} -ge $1
	then
		cd $dir
		for instance in *.d.pl
		do
			printf "TSP per instaza $instance\n"

			line_back="$(echo "$instance" | cut -d / -f 3)"
			line_time="$(echo "$instance" | cut -d / -f 3)"
			line_sol="$(echo "$instance" | cut -d / -f 3)"
			

			Nexec=$((2**$nchoices))
			for x in $(seq 0 $(($Nexec-1)))
			do
				choice=$(printf "%.${nchoices}d" `echo "obase=2;$x" | bc`)
				#echo $choice
				for i in $(seq 1 $nchoices)
				do
					eval ch${i}=${choice:((${i}-1)):1}
				done
				#echo $ch1,$ch2,$ch3
				out=($(eval $command))

				if test $? -ne 0 
				then
					echo "Esecuzione eclipse fallita"
					exit 1
				fi
				
				count=0
				sn=0
				#printf "\nConfronto\n"
				for i in "${out[@]}"
				do
					case $count in
						0|1) 
							if [ $x -eq 0 ]
							then 
								if [ $count -eq 0 ]
								then 
							 		sol=$i
								fi
							else 
								if [[ "$sol" == "$i" ]]
								then
									sn=1
								fi
							fi;;
						2) line_back="$line_back$sep$i";;
						3) line_time="$line_time$sep$i";;
					esac
					count=$((count+1))
				done

				if [ $x -eq 0 ] || [ "$sn" -eq 1 ]
				then
					line_sol="$line_sol${sep}sì"
				else
					line_sol="$line_sol${sep}no"
				fi
			done
			echo $line_sol >> ../../performance_test/$output_sol
			echo $line_back >> ../../performance_test/$output_back
			echo $line_time >> ../../performance_test/$output_time
		done
		cd .. 
	fi
done
cd ../performance_test

#python3 tsp_output.py $now $sep | tee /dev/tty > $now/ranking_result.txt


#out=($(eval $command0))

# count=0
# for i in "${out[@]}"
# do
# 	case $count in
# 		0) 
# 			sol=$i
# 			#echo $sol 
# 			line_sol=$line_sol$sep"$i";;
# 		1) ;;
# 		2) line_back="$line_back$sep$i";;
# 		3) line_time="$line_time$sep$i";;
# 	esac
# 	count=$((count+1))
# done