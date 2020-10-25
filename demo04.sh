#!/usr/bin/sh
if [ $# -eq 0 ]
then
echo "Error - Number missing form command line argument"
echo "Syntax : $0 number"
echo "Use to print multiplication table for given number"
exit 1
fi
n=$1
for i in 1 2 3 4 5 6 7 8 9 10 #or for ((  i =     0 ;  i <= 10;  i++  ))
do
echo "$n * $i = `expr $i \* $n`"
done