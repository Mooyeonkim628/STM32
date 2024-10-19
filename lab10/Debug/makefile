Automobile.o : Automobile.h Automobile.cc
	g++ -c Automobile.cc

main.o : main.cc Automobile.h
	g++ -c main.cc

main : Automobile.o main.o
	g++ Automobile.o main.o -o main