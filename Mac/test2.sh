#!/bin/bash


echo "GetMeReady v1.0 - Created by Mikael Levén"

# read -p "Hejsan: " $yn

# if [ $yn == "y" ] ; then
# 		echo "ok"
# fi

# break

# exit

echo 
echo "Do you want to install the Productivity package?"

select prodyn in "Yes" "No"; do
	case $prodyn in
		Yes ) echo "Productivity package choosen"; break;;
		No ) echo "Skipping Productivity package"; break;;
	esac
done


echo 
echo "Do you want to install the Developer package?"

select devyn in "Yes" "No"; do
	case $devyn in
		Yes ) echo "Developer package choosen"; break;;
		No ) echo "Skipping Developer package"; break;;
	esac
done


echo 
echo 
echo "==============================================="
echo "GetMeReady will install the following packages:"
echo 

if ["$prodyn" == "Yes"] ; then
	echo "Productivity: yes"
else
	echo "Productivity: yes"
fi

echo 
echo "Do you want to proceed?"

select go-ahead in "Yes" "No"; do
	case $go-ahead in
		Yes ) echo "Installing... "; break;;
		No ) echo "Aborted"; break;;
	esac
done