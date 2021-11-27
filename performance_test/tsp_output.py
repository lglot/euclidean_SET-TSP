import csv
import pprint
import sys


def ranking(file, str):
    with open(file) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                line_count += 1
            elif line_count == 1:
                file_op = {(i-1): [row[i], 0] for i in range(1, len(row))}
                line_count += 1
            else:
                xmin = min(row[1:])
                count = row[1:].count(xmin)
                if count == 1:
                    file_op[row[1:].index(xmin)][1] += 1
                else:

                    for i, x in enumerate(row[1:]):
                        if x == xmin:
                            file_op[i][1] += (1/count)

                line_count += 1
        ranking = {(k+1): [v[0], round(v[1], 2)] for k, v in enumerate(sorted(
            file_op.values(), key=lambda item: item[1], reverse=True))}
        print(str)
        pprint.pprint(ranking)
        print('\n')


if __name__ == "__main__":
    folder = sys.argv[1]
    sol = folder+'/output_sol.csv'
    back = folder+'/output_back.csv'
    time = folder+'/output_time.csv'
    with open(sol) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                line_count += 1
            elif line_count == 1:
                file_op = {(i-2): row[i] for i in range(2, len(row))}
                line_count += 1
            else:
                istance = row[0]
                pos = 1
                for word in row[1:]:
                    if ']' in word:
                        break
                    pos += 1

                for i, word in enumerate(row[(pos+1):]):
                    if word == 'no':
                        print(
                            f'Trovata una soluzione diversa per istanza {istance} con file {file_op[i]}')
                line_count += 1
        print(f'Processate {line_count} istanze.\n')

    ranking(back, "Classifica a punteggio per il numero dei backtracking")
    ranking(time, "Classifica a punteggio per il tempo di esecuzione")
