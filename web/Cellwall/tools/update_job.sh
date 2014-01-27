#!/bin/sh
#PBS -v CELLWALL_HOST,CELLWALL_DB,CELLWALL_USER,CELLWALL_PASSWD,CELLWALL_BASE
#PBS -l nodes=8:ppn=2

export PHYLIPVERSION="3.6"

cd $PBS_O_WORKDIR
pvmboot
./cellwall execute pvm 16
pvmhalt
