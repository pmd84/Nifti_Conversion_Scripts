#!/bin/bash
###### NIFTI converter for KKI DTI
### Unnecessarily complicated but such is life with KKI IT infrastructure
#JR 11/26/18
#PD 11/22/21

#some important path variables
#route=T:/amri/DATA/Children/3T
route=T:/amri/DTIanalysis/DSI/b-table-testing/Scanner-Test
dcm2niix=T:/amri/DTIanalysis/scripts/dcm2niix.exe
cwd=$(pwd)
me=T:/amri/DTIanalysis/scripts
rm -f $me/error.txt

#scanner1=MR1-Achieva-dStream
#scanner2=MR2-Ingenia-Elition-X
#pre=Pre-b-table-fix
#post=Post-b-table-fix

#change this:
#scanner=$scanner2
#scan=$post
#subject=3922_DSI
cd $route
scan_folds=$(echo *MR*)

for scan_fold in $scan_folds
do

scan="${scan_fold:0:3}"
cd $scan_fold

ID=$(ls)
cd $ID

#check to see that subject's directory exists
DSI_route="$route"/"$scan_fold"/"$ID"/DICOMs
echo "Converting in subject folder $DSI_route"

if [ ! -d nifti_convert ];
then
mkdir nifti_convert
fi
dwi_convert="$route"/"$scan_fold"/"$ID"/nifti_convert
cd $dwi_convert

#Convert DSI, send to dwi folder
# $dcm2niix -f "%p" -o $dwi_convert $DSI_route

# for dsi in DSI_51a DSI_50b
# do
# echo "changing name of $dsi scan"
# mv *$dsi*.bval "$ID"_"$dsi".bval
# mv *$dsi*.bvec "$ID"_"$dsi".bvec
# mv *$dsi*.json "$ID"_"$dsi".json
# mv *$dsi*.nii "$ID"_"$dsi".nii
# done

##Transform B-Tables
file_array=(*"DSI"*.bval *"DSI"*.bvec); #*.bvec
#echo "bval files are $file_array"
#echo "There are ${#file_array[@]} bval bvec scans"
#printf "%s\n" "${file_array[@]}"

rm *_nii_converted_btable.btable

for file in "${file_array[@]}"
do
  echo "transposing $file"
awk '
{
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' $file >> transposed_$file
done

echo "combining b-values and b-vectors into b-table"
for DSI in DSI_51a DSI_50b
do
paste transposed_"$ID"_"$DSI".bval transposed_"$ID"_"$DSI".bvec >> ../"$ID"_"$DSI"_"$scan"_nii_converted_btable.btable
done

rm transposed*
#$dcm2niix -f "$sub"_DSI_50b -o $dwi_convert "$DSI_route/${ID}_DSI_50b.dcm"
#$dcm2niix -f "$sub"_REV_FAT -o $dwi_convert "$DSI_route/${ID}_REV_FAT.dcm"
#$dcm2niix -f "$sub"_%_% -p y -z y -o $dwi_convert $DSI_route
cd $route

done


#done
