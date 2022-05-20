#!/bin/bash
###### NIFTI converter for KKI DTI to BIDS format
### Unnecessarily complicated but such is life with KKI IT infrastructure
#JR 11/26/18
#PD 11/22/21

#some important path variables
#route=T:/amri/DATA/Children/3T
route=T:/amri/DTIanalysis/NIFTI/CNIR_BIDS
dcm2niix=T:/amri/DTIanalysis/scripts/dcm2niix.exe
cwd=$(pwd)
me=T:/amri/DTIanalysis/scripts
rm -f $me/error.txt

#read in ID and DOS from sublist text file
for a in {1..1} # change this for number of subjets being ran {1..n}
do
ID=$(awk '{if($1=='$a'){print $2}}' $me/NIFTI_CNIR_BIDS_converter_list.txt)
DOS=$(awk '{if($1=='$a'){print $3}}' $me/NIFTI_CNIR_BIDS_converter_list.txt)
DOSonly=${DOS//_/} #removes underscores
sub=sub-"$ID" #creates bids subject directory name
ses=ses-"$DOSonly" #creates bids session name

#check to see that subject's directory exists
convert_directory=T:/amri/DTIanalysis/NIFTI/CNIR_BIDS
cd $convert_directory


if [ ! -d $sub ]; #Checks for subject folder
then
mkdir $sub
fi
cd $sub
#chmod -R 777 $convert_directory/$sub
echo $sub

if [ ! -d $ses ]; #Checks for session folder and creates it
then
mkdir $ses
fi
cd $ses

#check for all directories within subject
if [ ! -d dwi ];
then
mkdir dwi
fi
if [ ! -d anat ];
then
mkdir anat
fi
if [ ! -d fmap ];
then
mkdir fmap
fi

# if [ ! -d func ];
# then
# mkdir func
# fi

#defining paths for NIFTI (converted) folder
dwi_convert="$convert_directory"/"$sub"/"$ses"/dwi
anat_convert="$convert_directory"/"$sub"/"$ses"/anat
fmap_convert="$convert_directory"/"$sub"/"$ses"/fmap
#func_convert="$convert_directory"/"$sub"/"$ses"/func

#defining paths for raw DATA
data_route=$route/$ID/$DOS
DTI_route=$data_route/${ID}_DTI
T1_route=$data_route/${ID}_MPRA*
T2_route=$data_route/${ID}_DET2*
DSI_route=$data_route/${ID}_DSI

cd $data_route #go into raw data folder

#Convert MPRAGE, send to anat folder as T1w (only use second scan)
if [[ -d ${ID}_MPRAGE_32ch_1 && -d ${ID}_MPRAGE_32ch_2 ]];
	then
	echo "MULTIPLE MPRAGE SCANS FOR SUBJECT ${ID} - CHECK OUTPUT"
	T1_route=$route/$ID/$DOS/${ID}_MPRA*_2
fi
#dicom files need to be moved out of native directory for some reason
echo COPYING OVER MPRAGE DICOMS
cd $T1_route
pwd
cp $T1_route/* $T1_convert
#convert
$dcm2niix -f "$sub"_"$ses"_T1w -p y -z y -o $T1_convert


#OLD T1 Work
# T1_array=(${ID}_MPRAGE*/)
# echo "There are ${#T1_array[@]} MPRAGE Scans"
# if [ "${#T1_array[@]}" -gt 1 ]; then
# 	echo "There are multiple MPRAGE Scans - please choose only one to use and delete the other"
# 	for i in "${!T1_array[@]}"; do
# 		$dcm2niix -f "$sub"_T1w_"$((i+1))" -p y -z y -o $anat_convert ${T1_array[i]}
# 	done
# else
# 	$dcm2niix -f "$sub"_"$ses"_T1w_"$((i+1))" -p y -z y -o $anat_convert $T1_route
# fi
#
# #Convert DET2, send to anat folder
# $dcm2niix -f "$sub"_"$ses"_T2w -o $anat_convert $T2_route

#Convert DTI, send to dwi folder
# $dcm2niix -f "$sub"_acq-dti_dir-AP_run-1_dwi -o $dwi_convert $DTI_route/${ID}_DTI_1.rec
# $dcm2niix -f "$sub"_acq-dti_dir-AP_run-2_dwi -o $dwi_convert $DTI_route/${ID}_DTI_2.rec

#Convert DSI, send to dwi folder
$dcm2niix -f "%p" -o $dwi_convert $DSI_route

cd $dwi_convert
i=1
for dsi in DSI_51a DSI_50b
do
	echo "changing name of $dsi scan"
	mv *$dsi*.bval "$sub"_"$ses"_acq-dsi_dir-AP_run-"$i"_dwi.bval
	mv *$dsi*.bvec "$sub"_"$ses"_acq-dsi_dir-AP_run-"$i"_dwi.bvec
	mv *$dsi*.json "$sub"_"$ses"_acq-dsi_dir-AP_run-"$i"_dwi.json
	mv *$dsi*.nii "$sub"_"$ses"_acq-dsi_dir-AP_run-"$i"_dwi.nii
	let i+=1
done

#move REVFAT
if [*REV_FAT*]; then
	mv *REV_FAT*.bval $fmap_convert/"$sub"_"$ses"_dir-PA_run-1_epi.bval
	mv *REV_FAT*.bvec $fmap_convert/"$sub"_"$ses"_dir-PA_run-1_epi.bvec
	mv *REV_FAT*.json $fmap_convert/"$sub"_"$ses"_dir-PA_run-1_epi.json
	mv *REV_FAT*.nii $fmap_convert/"$sub"_"$ses"_dir-PA_run-1_epi.nii
	cd $fmap_convert
	#make a copy of the REVFAT so that QSIPrep works
	cp "$sub"_"$ses"_dir-PA_run-1_epi.bval "$sub"_"$ses"_dir-PA_run-2_epi.bval
	cp "$sub"_"$ses"_dir-PA_run-1_epi.bvec "$sub"_"$ses"_dir-PA_run-2_epi.bvec
	cp "$sub"_"$ses"_dir-PA_run-1_epi.json "$sub"_"$ses"_dir-PA_run-2_epi.json
	cp "$sub"_"$ses"_dir-PA_run-1_epi.nii "$sub"_"$ses"_dir-PA_run-2_epi.nii
fi

#Check on Conversions
#check that the DTI conversion worked
# if [ -e "$sub"_acq-dti_run-1_dwi ] && [ -e "$sub"_acq-dti_run-2_dwi ]; then
# 	echo DTI CONVERSION SUCCESSFUL
# 	else
# 	echo ERROR: DTI CONVERSION UNSUCCESSFUL
# 	printf "$ID $DOS failed at DTI\n" >> $me/error.txt
# fi
#check that the DSI conversion worked
if [ -e "$sub"_"$ses"_acq-dsi_run-1_dwi ] && [ -e "$sub"_"$ses"_acq-dsi_run-2_dwi ]; then
	echo DSI CONVERSION SUCCESSFUL
	else
	echo ERROR: DSI CONVERSION UNSUCCESSFUL
	printf "$ID $DOS failed at DSI\n" >> $me/error.txt
fi
cd $anat_convert
#check that the MPRAGE T1 conversion worked
if [ -e "$sub"_T1w*]; then
	echo MPRAGE T1 CONVERSION SUCCESSFUL
	else
	echo ERROR: MPRAGE T1 CONVERSION UNSUCCESSFUL
	printf "$ID $DOS failed at MPRAGE T1\n" >> $me/error.txt
fi
#check that the T2 conversion worked
if [ -e "$sub"_T2w]; then
	echo MPRAGE T2 CONVERSION SUCCESSFUL
	else
	echo ERROR: MPRAGE T2 CONVERSION UNSUCCESSFUL
	printf "$ID $DOS failed at MPRAGE T2\n" >> $me/error.txt
fi
cd $fmap_convert
#check that the REVFAT conversion worked
if [ -e "$sub"_acq-revfat_run-1_dwi ] && [ -e "$sub"_acq-revfat_run-2_dwi ]; then
	echo REVFAT CONVERSION SUCCESSFUL
	else
	echo ERROR: REFVAT CONVERSION UNSUCCESSFUL
	printf "$ID $DOS failed at REVFAT\n" >> $me/error.txt
fi

#Do stuff for DSI
# dsi_size=5
# rev_size=4
# cd $DSI_route
# count=1
# for a in $(ls *.dcm)
# do
# file_size=$(du -a $a | awk '{ print $1 }')
# size=${#file_size}
# if [ $size -eq $rev_size ];
# then
# echo Converting REVFAT
# cp $a $RF_convert
# $dcm2niix -f "$sub"_acq-revfat_run-1_epi $RF_convert
# rm -f $RF_convert/$a
# elif [ $size -eq $dsi_size ];
# then
# echo Converting DSI
# cp $a $DSI_convert
# $dcm2niix -f "$sub"_acq-dsi_run-1_epi $dwi_convert
# rm -f $DSI_convert/$a
# count=$(( count+1 ))
# fi
# done
#rmdir $HOLD



#Now do stuff for the T1. Not as simple as DTI
# cd $route/$ID/$DOS
# pwd
#
# if [[ -d ${ID}_MPRA*_1 && ${ID}_MPRA*_2 ]];
# 	then
# 	echo MULTIPLE MPRAGE SCANS FOR SUBJECT ${ID} - CHECK OUTPUT
# fi
# #dicom files need to be moved out of native directory for some reason
# echo COPYING OVER MPRAGE DICOMS
# cd $T1_route
# pwd
# cp $T1_route/* $T1_convert
# #convert
# $dcm2niix -b y -f ${ID}_MPRAGE $T1_convert
#
# #check that the conversion worked
# cd $T1_convert
# pwd
# if [ -e ${ID}_MPRAGE.nii ];
# 	then
# 	echo T1 CONVERSION SUCCESSFUL
# 	else
# 	echo ERROR: T1 CONVERSION FAILED
# 	printf "$ID $DOS failed at T1 conversion \n" >> $me/error.txt
# fi
# cd $T1_convert
#
# #clean out the directory after conversion
# ls | grep -v ${ID}_MPRAGE.nii | xargs rm

#Do stuff for the T2. A mf nightmare
#check subject directory for multiple T2 acquisitions. If there are, just figure out which one to use and do that manually
# cd $data_check
# if [[ -d ${ID}_DET2??_2 ]];
# 	then
# 	echo WARNING: MULTIPLE T2 DIRECTORIES EXIST FOR THIS SUBJECT.
# 	cp $data_check/${ID}_DET2??_2/* $T2_convert
# 	for filename in $T2_convert
# 	do
# 	[ -f "$filename" ] || continue
# 	mv "$filename" "${filename//002./}"
# 	done
# 	$dcm2niix -b y -f ${ID}_T2 $T2_convert
#
# 	ls | grep -v ${ID}_T2_e2.nii | xargs rm
# 	mv ${ID}_T2_e2.nii ${ID}_T2.nii
# 	else
# 	cd $T2_convert
# 	pwd
# 	echo COPYING OVER T2 DICOMS
# 	cp $T2_route/* $T2_convert
# 	for filename in $T2_convert
# 	do
# 	[ -f "$filename" ] || continue
# 	mv "$filename" "${filename//002./}"
# 	done
# 	$dcm2niix -b y -f ${ID}_T2 $T2_convert
#
# 	ls | grep -v ${ID}_T2_e2.nii | xargs rm
# 	mv ${ID}_T2_e2.nii ${ID}_T2.nii
# fi
# if [ -e $T2_convert/${ID}_T2.nii ];
# 	then
# 	echo T2 conversion SUCCESSFUL
# 	else
# 	echo T2 conversion FAILED
# 	printf "$ID $DOS failed at T2 conversion \n" >> $me/error.txt
# fi

# #remove all the extra files and folders
# mv $DTI_convert/* $convert_directory/$name/
# mv $T1_convert/${ID}_MPRAGE.nii $convert_directory/$name
# mv $T2_convert/${ID}_T2.nii $convert_directory/$name
# mv $DSI_convert/* $convert_directory/$name/
# mv $RF_convert/* $convert_directory/$name/
#
# read -p "DID IT WORK? CHECK Folder"
#
# rmdir $DTI_convert
# rmdir $T1_convert
# rmdir $T2_convert
# rmdir $DSI_convert
# rmdir $RF_convert

# #check files
# cd $data_check
# if [ -d ${ID}_DET2?? ];
# 	then
# 	cd ${ID}_DET2??
# 	pwd
# 	scanner=$(cat info | awk '$2 == "Manufacturer" {print $5;}')
# 	else
# 	if [ -d ${ID}_FLAIR ];
# 		then
# 		cd ${ID}_FLAIR
# 		pwd
# 		scanner=$(cat info | awk '$2 == "Manufacturer" {print $5;}')
# 		else
# 		if [ -d ${ID}_MPRAGE ];
# 			then
# 			cd ${ID}_MPRAGE
# 			pwd
# 			scanner=$(cat info | awk '$2 == "Manufacturer" {print $5;}')
# 			else
# 			echo no dicom directories
# 			#exit 1
# 		fi
# 	fi
# fi
# echo $scanner
# printf "$ID $scanner\n" >> T:/amri/DTIanalysis/scripts/scanner.txt
#
# echo Subject ${ID} complete
done
