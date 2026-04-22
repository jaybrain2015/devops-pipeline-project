#!/bin/bash

command_exists(){
	command -v "$1" &> /dev/null
}



if  command_exists git ; then
	echo "git is installed"
else
	echo "git is Not installed"
fi

if command_exists dockeri ; then
	echo "dockeri exist"
else 
	echo "dockeri doesnt exist"
fi 
