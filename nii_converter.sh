#!/bin/bash
###### NIFTI converter for KKI DTI
### Unnecessarily complicated but such is life with KKI IT infrastructure
#JR 11/26/18
#PD 11/22/21

#some important path variables
route=T:/amri/DATA/Children/3T
dcm2niix=T:/amri/DTIanalysis/scripts/dcm2niix.exe
cwd=$(pwd)
me=T:/amri/DTIanalysis/scripts
rm -f $me/error.txt

#read in ID and DOS from sublist text file
for a in {1..1} # change this for number of subjets being ran {1..n}
do
ID=$(awk '{if($1=='$a'){print $2}}' $me/NIFTI_converter_list.txt)
DOS=$(awk '{if($1=='$a'){print $3}}' $me/NIFTI_converter_list.txt)

#check to see that subject's directory exists
convert_directory=T:/amri/DTIanalysis/NIFTI
cd $convert_directory
name=${ID}_${DOS}
if [ ! -d $name ];
then
mkdir $name
fi
cd $name
chmod -R 777 $convert_directory/$name
echo $name

#check for all directories within subject
if [ ! -d DTI ];
then
mkdir DTI
fi
if [ ! -d MPRAGE ];
then
mkdir MPRAGE
fi
if [ ! -d T2 ];
then
mkdir T2
fi
if [ ! -d DSI ];
then
mkdir DSI
fi
# if [ ! -d REVFAT ];
# then
# mkdir REVFAT
# fi

#defining paths for NIFTI (converted) folder
DTI_convert=$convert_directory/$name/DTI
T1_convert=$convert_directory/$name/MPRAGE
T2_convert=$convert_directory/$name/T2
DSI_convert=$convert_directory/$name/DSI
#RF_convert=$convert_directory/$name/REVFAT

#defining paths for raw DATA
DTI_route=$route/$ID/$DOS/${ID}_DTI
T1_route=$route/$ID/$DOS/${ID}_MPRA*
data_check=$route/$ID/$DOS
T2_route=$route/$ID/$DOS/${ID}_DET2*
DSI_route=$route/$ID/$DOS/${ID}_DSI

#Do stuff for DTI
cd $DTI_route
pwd

#convert DTI
$dcm2niix -f ${ID}_DTI_1 -o $DTI_convert $DTI_route/${ID}_DTI_1.rec
$dcm2niix -f ${ID}_DTI_2 -o $DTI_convert $DTI_route/${ID}_DTI_2.rec

#check that the conversion worked
cd $DTI_convert
if [ -e ${ID}_DTI_1.nii ] && [ -e ${ID}_DTI_2.nii ];
then
	echo DTI CONVERSION SUCCESSFUL
	else
	echo ERROR: DTI CONVERSION UNSUCCESSFUL
	printf "$ID $DOS failed at DTI\n" >> $me/error.txt
	#exit 1
fi

#clean up DTI files
rm *_ADC.nii

if [[ -d $DSI_route ]];
then
	cd $DSI_convert
	$dcm2niix -f "%p" -o $DSI_convert $DSI_route

	for dsi in DSI_51a DSI_50b REV_FAT
	do
		echo "changing name of $dsi scan"
		mv *$dsi*.bval "$ID"_"$dsi".bval
		mv *$dsi*.bvec "$ID"_"$dsi".bvec
		mv *$dsi*.json "$ID"_"$dsi".json
		mv *$dsi*.nii "$ID"_"$dsi".nii
	done

	#check that the conversion worked

	if [ -e ${ID}_DSI_50b.nii ] && [ -e ${ID}_DSI_51a.nii ];
	then
		echo DSI CONVERSION SUCCESSFUL
	else
		echo ERROR: DSI CONVERSION UNSUCCESSFUL
		printf "$ID $DOS failed at DSI\n" >> $me/error.txt
		#exit 1
	fi

	#check that the conversion worked
	if [ -e ${ID}_REV_FAT.nii ];
	then
		echo REVFAT CONVERSION SUCCESSFUL
	else
		echo ERROR: REVFAT CONVERSION UNSUCCESSFUL
		printf "$ID $DOS failed at REVFAT\n" >> $me/error.txt
		#exit 1
	fi
fi

#OLD DSI SCRIPT
#in DATA folder, convert DSI and REVFAT files -
#cd $HOLD
#dsi_size=5
#rev_size=4
# count=1
# for a in $(ls *.dcm)
# do
# file_size=$(du -a $a | awk '{ print $1 }')
# size=${#file_size}
# if [ $size -eq $rev_size ];
# then
# echo Converting REVFAT
# cp $a $RF_convert
# $dcm2niix -f ${ID}_REVFAT $RF_convert
# rm -f $RF_convert/$a
# elif [ $size -eq $dsi_size ];
# then
# echo Converting DSI
# cp $a $DSI_convert
# $dcm2niix -f ${ID}_DSI_${count} $DSI_convert
# rm -f $DSI_convert/$a
# count=$(( count+1 ))
# fi
# done
# #rmdir $HOLD



#Now do stuff for the T1. Not as simple as DTI
cd $route/$ID/$DOS
pwd

if [[ -d ${ID}_MPRAGE_32ch_1 && -d ${ID}_MPRAGE_32ch_2 ]];
	then
	echo MULTIPLE MPRAGE SCANS FOR SUBJECT ${ID} - CHECK OUTPUT
	T1_route=$route/$ID/$DOS/${ID}_MPRA*_2
fi
#dicom files need to be moved out of native directory for some reason
echo COPYING OVER MPRAGE DICOMS
cd $T1_route
pwd
cp $T1_route/* $T1_convert
#convert
$dcm2niix -f ${ID}_MPRAGE $T1_convert

#check that the conversion worked
cd $T1_convert
pwd
if [ -e ${ID}_MPRAGE.nii ];
	then
	echo T1 CONVERSION SUCCESSFUL
	else
	echo ERROR: T1 CONVERSION FAILED
	printf "$ID $DOS failed at T1 conversion \n" >> $me/error.txt
fi
cd $T1_convert

#clean out the directory after conversion
ls | grep -v ${ID}_MPRAGE.nii | xargs rm

#Do stuff for the T2. A mf nightmare
#check subject directory for multiple T2 acquisitions. If there are, just figure out which one to use and do that manually
cd $data_check
if [[ -d ${ID}_DET2??_2 ]];
	then
	echo WARNING: MULTIPLE T2 DIRECTORIES EXIST FOR THIS SUBJECT.
	cp $data_check/${ID}_DET2??_2/* $T2_convert
	for filename in $T2_convert
	do
	[ -f "$filename" ] || continue
	mv "$filename" "${filename//002./}"
	done
	$dcm2niix -f ${ID}_T2 $T2_convert

	ls | grep -v ${ID}_T2_e2.nii | xargs rm
	mv ${ID}_T2_e2.nii ${ID}_T2.nii
	else
	cd $T2_convert
	pwd
	echo COPYING OVER T2 DICOMS
	cp $T2_route/* $T2_convert
	for filename in $T2_convert
	do
	[ -f "$filename" ] || continue
	mv "$filename" "${filename//002./}"
	done
	$dcm2niix -f ${ID}_T2 $T2_convert

	ls | grep -v ${ID}_T2_e2.nii | xargs rm
	mv ${ID}_T2_e2.nii ${ID}_T2.nii
fi
if [ -e $T2_convert/${ID}_T2.nii ];
	then
	echo T2 conversion SUCCESSFUL
	else
	echo T2 conversion FAILED
	printf "$ID $DOS failed at T2 conversion \n" >> $me/error.txt
fi

#remove all the extra files and folders
mv $DTI_convert/* $convert_directory/$name/
mv $T1_convert/${ID}_MPRAGE.nii $convert_directory/$name
mv $T2_convert/${ID}_T2.nii $convert_directory/$name
mv $DSI_convert/* $convert_directory/$name/
#mv $RF_convert/* $convert_directory/$name/
rmdir $DTI_convert
rmdir $T1_convert
rmdir $T2_convert
rmdir $DSI_convert
#rmdir $RF_convert

#check files
cd $data_check
if [ -d ${ID}_DET2?? ];
	then
	cd ${ID}_DET2??
	pwd
	scanner=$(cat info | awk '$2 == "Manufacturer" {print $5;}')
	else
	if [ -d ${ID}_FLAIR ];
		then
		cd ${ID}_FLAIR
		pwd
		scanner=$(cat info | awk '$2 == "Manufacturer" {print $5;}')
		else
		if [ -d ${ID}_MPRAGE ];
			then
			cd ${ID}_MPRAGE
			pwd
			scanner=$(cat info | awk '$2 == "Manufacturer" {print $5;}')
			else
			echo no dicom directories
			#exit 1
		fi
	fi
fi
echo $scanner
printf "$ID $scanner\n" >> T:/amri/DTIanalysis/scripts/scanner.txt

echo Subject ${ID} complete
done
