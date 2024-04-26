#!/bin/bash

if [ "$1" == "--full" ]; then
	echo "Collecting all the packages information"
elif [ "$1" == "--package" ] && [ "$2" != "" ]; then
  echo "Searching by package $2"
else
  echo "Please, call $0 with the parameter"
  echo " --full # To generate a complete list of all the packages in the content view"
  echo " --package <package name> # To generate a list of packages in the content view, based on the name"
	echo
  echo "exiting ..."
	exit
fi


# Variables
ERRATA_FILE="/tmp/full_errata.log"
>$ERRATA_FILE

OUTPUT_FILE="/tmp/full_report.csv"
>$OUTPUT_FILE

# DB Query. The hammer was spending too much time
echo "select ke.id,ke.errata_id,ke.errata_type,ke.severity,kep.* from katello_errata as ke, katello_erratum_packages as kep where ke.id=kep.erratum_id" | su - postgres -c "psql foreman" >$ERRATA_FILE

# The CSV header
echo "pkg_name,cv_id,cv_name,cv_label,cv_last_publish,cvv_id,cvv_name,cvv_version,cvv_description,cvv_lfc,errata_id,errata_type,errata_sev" >$OUTPUT_FILE

# Generating a list of CVs
#hammer --csv --no-headers content-view list | grep -v Default | while read cv
hammer --csv --no-headers content-view list | while read cv
do
  cv_id=$(echo $cv | cut -d, -f1)
  cv_name=$(echo $cv | cut -d, -f2)
  cv_label=$(echo $cv | cut -d, -f3)
  cv_last_publish=$(echo $cv | cut -d, -f5)

  #echo "- $cv_id,\"$cv_name\",$cv_label,$cv_last_publish"

  # Generating a list of CVs by version
	hammer --csv --no-headers content-view version list | while read cvv
	do
		cvv_id=$(echo $cvv | cut -d, -f1)
		cvv_name_report=$(echo $cvv | cut -d, -f2)
		cvv_name=$(echo $cvv | cut -d, -f2 | sed 's/ [0-9].[0-9]//g')
		cvv_version=$(echo $cvv | cut -d, -f3)
		cvv_desc=$(echo $cvv | cut -d, -f4)
		cvv_lfc=$(echo $cvv | cut -d, -f5)

		#echo "-- $cvv_id,$cvv_name,$cvv_version,$cvv_desc,$cvv_lfc"

		# Matching the CV with the version
		if [ "$cv_name" == "$cvv_name" ]; then
			#echo "-- $cvv_id,$cvv_name,$cvv_version,$cvv_desc,$cvv_lfc"
			#hammer --csv --no-headers package list --content-view-id 2 --content-view-version-id 5 --search 'filename ~ gofer' --fields filename
			if [ "$2" == "" ]; then
 				command="hammer --csv --no-headers package list --content-view-id $cv_id --content-view-version-id $cvv_id --fields filename"
			else
 				command="hammer --csv --no-headers package list --content-view-id $cv_id --content-view-version-id $cvv_id --search filename~${2} --fields filename"
			fi
			# Based on the parameters, this will pass through all the packages or only for the selected ones
			$(echo $command) | while read pkg_name
			do
				if [ "$pkg_name" != "" ]; then
        	#echo "AUDIT: cv: $cv_name, cvv: $cvv_name_report, package: '$pkg_name'"
					count=$(grep "| $pkg_name" $ERRATA_FILE | wc -l)
        	#echo "AUDIT: count: $count"
					if [ "$count" -eq 0 ]; then
						:
					elif [ "$count" -eq 1 ]; then
						#echo "- $pkg_name"
						errata_list=$(grep "| $pkg_name" $ERRATA_FILE | awk '{print $3}')
						errata_type=$(grep "| $pkg_name" $ERRATA_FILE | awk '{print $5}')
						errata_sev=$(grep "| $pkg_name" $ERRATA_FILE | awk '{print $7}')
						# Generating the content of the CSV
						echo "$pkg_name,$cv_id,$cv_name,$cv_label,$cv_last_publish,$cvv_id,$cvv_name_report,$cvv_version,$cvv_description,$cvv_lfc,$errata_list,$errata_type,$errata_sev" >>$OUTPUT_FILE
					else
					  grep "| $pkg_name" $ERRATA_FILE | while read each_errata
					  do
							errata_list=$(echo $each_errata | awk '{print $3}')
							errata_type=$(echo $each_errata | awk '{print $5}')
							errata_sev=$(echo $each_errata | awk '{print $7}')
							# Generating the content of the CSV
							echo "$pkg_name,$cv_id,$cv_name,$cv_label,$cv_last_publish,$cvv_id,$cvv_name_report,$cvv_version,$cvv_description,$cvv_lfc,$errata_list,$errata_type,$errata_sev" >>$OUTPUT_FILE
					  done
					fi
				fi
			done
		fi
	done
done

echo "Please, check $OUTPUT_FILE"