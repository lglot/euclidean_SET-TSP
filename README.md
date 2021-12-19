# EUCLIDEAN SET-TSP WITH CLP(FD)

Solver CLP(FD) che risolve il problema del SET-TSP Euclideo. 
Utilizza alcuni vincoli per ottimizzare la ricerca:

- Clockwise constraint (Impone che i set che hanno almeno un nodo sulla convex hull vengano visitati in senso orario)
- Nocrossing constraint (Impone l'assenza di incroci)
- Sorted (Impone che i set che hanno almeno un nodo sulla convex hull vengano visitati nello stesso ordine con cui appaiono nella convex hull)

## Requirements

- [Eclipse Version 7.0](https://eclipseclp.org/download.html)
- [Gnuplot](http://www.gnuplot.info/)

## How to use

Il file set_tsp.ecl contiene il predicato main che si occupa di definire i vincoli fondamentali del set-tsp, include i moduli esterni, le librerie, l'istanza, ed effettua la ricerca, ed eventualmente infine fa il plot della soluzione utilizzando la  libreria gnuplot; è invocabile useguendo uno dei seguenti comandi:

### Senza stampa del plot

  ```console
  eclipse -f set_tsp.ecl -f /path/to/instance -e "set_tsp" 
  ```

### Con Plot
  
  ```console
  eclipse -f set_tsp.ecl -f /path/to/instance -e "set_tsp(NameFile)" 
  ```

Se NameFile è una variabile, alla fine della ricerca  mostra a schermo il plot del set-tsp trovato , mentre se NameFile è ground salva il plot in un file con nome NameFile.png

Nota: la libreria gnuplot necessita dell'omonimo software installato sul sistema operativo: <http://www.gnuplot.info/>

## Scegliere i vincoli da utilizzare

Il sorver è possibile lanciarlo anche scegliendo quali vincoli di ottimizzazione utillizzare.
Infatti è possibile lanciare dei goal con tre paramentri:

- set_tsp_with_choice(ClockwiseChoice,NoCrossingChoice,SortChoice)

Dove i 3 parametri corrispondo a tre variabili booleane che impongo al solver di utilizzare o non utilizzare rispoettivamente i vincoli di senso orario, assenza incroci, ordine.

Esempio:

```console
eclipse -f set_tsp.ecl -f /path/to/instance -e "set_tsp(1,0,0)"
```

In questo caso la ricerca viene fatta imponendo solo il vincolo di senso orario(Clockwise).
**Di default viene eseguito il goal "set_tsp(1,1,0)"**

Se si vuole stampare anche il plot:

```console
eclipse -f set_tsp.ecl -f /path/to/instance -e "set_tsp(1,1,0,Namefile)"
```

## Performance Test

Script per testare le performance di tutte le combinazioni di utilizzo o non utilizzo dei 3 vincoli di ottimizazzione con le istanze richieste. In particolare controlla che venga trovata sempre la soluzione ottima, e calcola il tempo medio di esecuzione e il numero medio di backtracking

```console
performance_test/RUNME.sh Ni Nf /path/to/instances-clustered
```

I tre parametri indicano:

- Ni : Numero dei nodi delle istanze da cui far partire i test
- Nf : Numero dei nodi delle istanze dove i test devono terminare
- /path/to/instances-clustered : Path delle istanze clusterizzate

Esempio

```console
performance_test/RUNME.sh 14 34 ./instances-clustered
```
