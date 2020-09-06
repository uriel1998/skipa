#!/bin/bash

########################################################################
#	Reading tags from several types of files
#
#   Get tags from metadata
#	Get tags from filename
########################################################################

#pdftohtml
#html2text
#stat
#date
#exiftool

PDF_Text=""
PDF_Create_Time=""
PDF_FNCreate_Time=""
PDF_Author=""
PDF_Creator=""
PDF_Keywords="" #not an array - should be space or comma separated
PDF_FNTags=""
PDF_Subject=""
PDF_Title=""
PDF_FNTitle=""
PDF_FileMod_Time=""
PDF_File="" #actual filename, either from program calling it or from $1


get_filename_tags {
   
    baseFN=$(basename ${PDF_File})
    
    #does it have tags in the filename?
    if [[ ${baseFN} =~ "[" ]];then
        PDF_FNTags=$(echo ${baseFN} | cut -d "[" -f2 | cut -d "]" -f1)
    fi
    
    #does it have a date in the filename at the end like GScan2PDF does?
    if [[ ${baseFN} =~ [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]];then
        PDF_FNTitle=$(echo ${baseFN} | cut -d "[" -f1 | sed -n "s/\(^.*\)-[0-9][0-9][0-9][0-9].*$/\1/p")
        scratch3=$(echo ${baseFN} | cut -d "[" -f1 | sed -n "s/^.*-\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*$/\1/p")
        PDF_FNCreate_Time=$(printf "%s 00:00:00+00:00" "$scratch3")
    else
        PDF_FNTitle=$(echo ${baseFN} | cut -d "[" -f1)
    fi
}

get_metadata_tags {

    PDF_Text=$(pdftohtml -stdout -s -i -noframes %f | html2text)
    if [ -z "$PDF_Text" ];then
        PDF_Text=$(pdftohtml -stdout -s -i -hidden -noframes %f | html2text)
    fi
    
    scratch1=$(stat -c '%Y' ${PDF_File})
    PDF_FileMod_Time=$(date -d "@$(stat -c '%Y' ${scratch1})" '+%Y:%m:%d %H:%M:%S%:z')
    
    scratch2=$(exiftool -T -sep ' ' -Author -Keywords -Subject -Title -CreateDate ${PDF_File})
    PDF_Author=$(echo "${scratch2}" | awk -F $'\t' '{print $1}')
    PDF_Keywords=$(echo "${scratch2}" | awk -F $'\t' '{print $2}')
    PDF_Subject=$(echo "${scratch2}" | awk -F $'\t' '{print $3}')
    PDF_Title=$(echo "${scratch2}" | awk -F $'\t' '{print $4}')
    PDF_Create_Time=$(echo "${scratch2}" | awk -F $'\t' '{print $5}')


}


########################################################################
# Definitions
########################################################################
OurFile=()
OurMimetype=
CheckOCR=
InputFile=
DataStoredDir=$XDG_DATA_HOME/organ_izer


########################################################################
# Functions
########################################################################

# For config file
#if [ -f "$XDG_DATA_HOME/organ_izer/organ.rc" ];then
#	readarray -t line < "$XDG_DATA_HOME/organ_izer/organ.rc"
#fi

function get_exifdata {

    exiftool 
    
}


# https://stackoverflow.com/questions/23356779/how-can-i-store-find-command-result-as-arrays-in-bash
# read the args (which should be files) into an array
if [ -d "$InputFile" ];then
		
		while IFS=  read -r -d $'\0'; do
			OurFile+=("$REPLY")
		done < <(find . -name ${input} -print0)
	else
		OurFile+=("$InputFile")
fi

for file in "${OurFile[@]}"
do
	file -p "$file"
	mimetype=$(file -p "$file")

	case "$mimetype" in
		) #PDF
        #(with -i switch) ./test.pdf: application/pdf; charset=binary
        #./test.pdf: PDF document, version 1.4

		;;
		) #jpg
		;;
		) #mp3
		;;
		) #png
		;;
		) #doc/docx
		;;
	esac
		
	# do we have a reader for that mimetype? - exiftool or pdfinfo
    # exiftool can apparently get most of what we want.

	# collect the metadata that we're looking for

	 # can I use grep or somesuch to parse the lines of what metadata is stored?
	 # then awk to cut it out
	 # pdf jpg png | title
	 # pdf | subject
	 # etc
#title 
#subject 
#keywords 
#author 
#creator 
#creation date 
# I WANT WHETHER OR NOT THERE'S TEXT	look at PDFFONT
# If no font or type 3 (not TTF or OTF, I'm guessing) then you're going to not have text
done


##############################################################################
# Are we sourced?
# From http://stackoverflow.com/questions/2683279/ddg#34642589
##############################################################################

# Try to execute a `return` statement,
# but do it in a sub-shell and catch the results.
# If this script isn't sourced, that will raise an error.
$(return >/dev/null 2>&1)

# What exit code did that give?
if [ "$?" -eq "0" ];then
    #echo "[info] Function read_vcard ready to go."
    OUTPUT=0
else
    OUTPUT=1
    if [ "$#" = 0 ];then
        echo "Please call this as a function or with the filename as the first argument."
    else
        if [ -f "$1" ];then
            SelectedVcard="$1"
        else
            #if it's coming from pplsearch for preview
            SelectedVcard=$(echo "$1" | awk -F ':' '{print $2}' | realpath -p)
        fi
        if [ ! -f "$SelectedVcard" ];then
            echo "File not found..."
            exit 1
        fi
        SUCCESS=0
        output=$(read_vcard)
        if [ $SUCCESS -eq 0 ];then
            # If it gets here, it has to be standalone
                echo "$output"
        else
            exit 99
        fi
    fi
fi

