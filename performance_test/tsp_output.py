import csv
import pprint
import sys


def average(l):
    return sum(l)/len(l)


def ranking(sep, file, str):
    values = []
    with open(file) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=sep)
        line_count = 0
        for row in csv_reader:
            if line_count == 0:
                line_count += 1
            elif line_count == 1:
                file_op = {(i-1): [row[i]]
                           for i in range(1, len(row))}
                for i in range(len(row)-1):
                    values.append([])
                line_count += 1
            else:
                for i, value in enumerate(row[1:]):
                    values[i].append(float(value))
                # xmin = min(row[1:])
                # count = row[1:].count(xmin)
                # if count == 1:
                #     file_op[row[1:].index(xmin)][1] += 1
                # else:

                #     for i, x in enumerate(row[1:]):
                #         if x == xmin:
                #             file_op[i][1] += (1/count)

                line_count += 1
        # print(len(values))
        ranking = {(k+1): [v[0], round(average(values[k]), 2)]
                   for k, v in file_op.items()}
        print(str)
        pprint.pprint(ranking)
        print('\n')


if __name__ == "__main__":
    
    try:
        folder = sys.argv[1]
        sep = sys.argv[2]
    except IndexError:
        folder = ""
        sep = ""
    if folder == "" or sep == "":
        print("Argument missing")
    else:
        sol = folder+'/output_sol.csv'
        back = folder+'/output_back.csv'
        time = folder+'/output_time.csv'
        with open(sol) as csv_file:
            csv_reader = csv.reader(csv_file, delimiter=sep)
            line_count = 0
            for row in csv_reader:
                if line_count == 0:
                    line_count += 1
                elif line_count == 1:
                    file_op = {(i-1): row[i] for i in range(1, len(row))}
                    print(file_op)
                    line_count += 1
                else:
                    istance = row[0]
                    # pos = 2
                    # for word in row[1:]:
                    #    if ']' in word:
                    #        break
                    #    pos += 1

                    for i, word in enumerate(row[1:]):
                        if word == 'no':
                            print(
                                f'Trovata una soluzione diversa per istanza {istance} con procedura {file_op[i]}')
                    line_count += 1
            print(f'Processate {line_count-2} istanze.\n')
        print("Test performance di tutte le combinazioni dei vincoli")
        ranking(sep, back, "Numero medio backtracking")
        ranking(sep, time, "Tempo medio di esecuzione")
