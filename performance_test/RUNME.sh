#!/bin/bash

if test $# -ne 3
then
        printf "Uso: RUNME.sh Ni Nf /path/to/instances-clustered\nNi: Numero nodi istanza iniziale\nNf: numero nodi istanza finale\n"; exit 1;
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"
cd ..
PROJECT_DIR=$(pwd)
path_to_instances_clustered=$3

## Test per lanciare eclipse su WSL in Windows
which eclipse
if test $? -ne 0 
	then
		eclipseCmd="eclipse.exe"
		PROJECT_DIR=$(wslpath -m "$PROJECT_DIR")
	else 
		eclipseCmd="eclipse" 
	fi

command='$eclipseCmd -f $instance -f "${PROJECT_DIR}/set_tsp.ecl" -e "set_tsp_with_choice($ch1,$ch2,$ch3)" |
		grep -e "numero_backtracking" -e "Succ" -e "Pred" -e "time" |  	
		cut -f 2 -d : | tr -d $"\r" | tr -d " "'




now=$(date +'%F_%H%M')
mkdir "$SCRIPT_DIR/$now"

output_back="$SCRIPT_DIR/$now/output_back.csv"
output_time="$SCRIPT_DIR/$now/output_time.csv"
output_sol="$SCRIPT_DIR/$now/output_sol.csv"

nchoices=3;
sep=";"
#Ch1 = Clockwise(C)
#Ch2 = NoCrossing(N)
#Ch3 = Sort(S)
echo "sep="$sep"" | tee "$output_back" | tee "$output_time" > "$output_sol"

## Intestazione output - Da cambiare a mano se cambiano i vincoli da testare
header="istance;000:None;001:S;010:N;011:NS;100:C;101:CS;110:CN;111:CNS\n"	

printf "$header" >> "$output_back"
printf "$header" >> "$output_time"
printf "$header" >> "$output_sol"


cd "$path_to_instances_clustered"
for dir in *
do
	if test -d "$dir" && test "${dir:8:2}" -le $2 && test "${dir:8:2}" -ge "$1"
	then
		cd "$dir"
		for instance in *.d.pl
		do
			printf "TSP per instaza "$instance"\n"

			line_back="$(echo "$instance" | cut -d / -f 3)"
			line_time="$(echo "$instance" | cut -d / -f 3)"
			line_sol="$(echo "$instance" | cut -d / -f 3)"
			

			Nexec=$((2**$nchoices))
			for x in $(seq 0 $(($Nexec-1)))
			do
				choice=$(printf "%.${nchoices}d" `echo "obase=2;$x" | bc`)
				for i in $(seq 1 $nchoices)
				do
					eval ch${i}=${choice:((${i}-1)):1}
				done
				#echo $ch1,$ch2,$ch3
				out=($(eval "$command"))
				printf "${choice},"
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
			echo "$line_sol" >> "$output_sol"
			echo "$line_back" >> "$output_back"
			echo "$line_time" >> "$output_time"
			printf "\n"
		done
		cd .. 
	fi
done
python3 "$SCRIPT_DIR/tsp_output.py" "$SCRIPT_DIR/$now" "$sep" | tee /dev/tty > "$SCRIPT_DIR/$now/ranking_result.txt"