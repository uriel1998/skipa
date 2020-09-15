#!/bin/bash

########################################################################
#	Reading tags from several types of files
#   by Steven Saus (c)2020-09-13
#   Licensed under the MIT license
########################################################################

########################################################################
# Definitions 
########################################################################
init_vars (){
	PDF_Text=""
	PDF_Create_Time=""
	PDF_FNCreate_Time=""
	PDF_Author=""
	PDF_Keywords="" #not an array - should be space or comma separated
	PDF_FNTags=""
	PDF_Subject=""
	PDF_Title=""
	PDF_FNTitle=""
	PDF_File="" #actual filename, either from program calling it or from $1
	PDF_Dir=""
	ARGVAL=""
	FNARGVAL=""
	tempdir=$(mktemp -d)
    RETURNVAL=""
}

tags_to_filename (){
        # Needed for when I'm directory processing
        PDF_FileString=$(basename "${PDF_File}")

        
		#write to exif first
        # NOTE THAT IT OVERWRITES IN PLACE
		exiftool -overwrite_original_in_place -Author="${PDF_Author}" -Keywords="${PDF_Keywords}" -Subject="${PDF_Subject}" -Title="${PDF_Title}" -CreateDate="${PDF_Create_Time}" "${PDF_File}"
		
		mv "${PDF_File}" "$tempdir/${PDF_FileString}"
		#TITLE-YYYY-MM-DD[tag tag tag tag].pdf
		#move original to tempdir
		
		#create new fn string
		T2a=$(echo "${PDF_Title}" | detox --inline)
		T2b=$(echo "${PDF_Create_Time}" | cut -d " " -f1 | sed s/:/-/g)
		T2FN=$(printf "%s/%s-%s[%s].pdf" "${PDF_Dir}" "$T2a" "$T2b" "${PDF_Keywords}")
		cp "$tempdir/${PDF_FileString}" "${T2FN}"
		#copy old to new T2FN string
	
}

########################################################################
# Getting tags embedded in filename, if possible
# Currently looking for tags from TagSpaces 
# And dates from GScan2PDF 
# NAME-YYYY-MM-DD[TAG TAG TAG].pdf
########################################################################
get_filename_tags (){
   
	baseFN=$(basename "${PDF_File}")
	
	#TODO - for Mendeley renamed stuff
	#A Decade in Internet Time Symposium on the Dynamics of the Internet and Society, September 2011 - Boyd, Marwick, Boyd - Social Privacy.pdf
	#JOURNAL - AUTHOR - TITLE - YEAR
	
	if [[ ${baseFN} =~ "[" ]];then
		PDF_FNTags=$(echo "${baseFN}" | cut -d "[" -f2 | cut -d "]" -f1)
		if [[ "${PDF_FNTags}" =~ "[" ]];then # ensuring there isn't a [[ tag tag ]] scenario
			PDF_FNTags=$(echo "${PDF_FNTags}" | cut -d "[" -f2 | cut -d "]" -f1)
		fi
	fi
	
	#does it have a date in the filename at the end like GScan2PDF does?
	if [[ "${baseFN}" =~ [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]];then
		PDF_FNTitle=$(echo "${baseFN//_/ }" | cut -d "[" -f1 | sed -n "s/\(^.*\)-[0-9][0-9][0-9][0-9].*$/\1/p")
		scratch3=$(echo "${baseFN}" | cut -d "[" -f1 | sed -n "s/^.*-\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*$/\1/p")
		PDF_FNCreate_Time=$(printf "%s 00:00:00+00:00" "$scratch3" | sed 's/-/:/g')
	else
		PDF_FNTitle=$(echo "${baseFN//_/ }" | cut -d "[" -f1 )
	fi
}

########################################################################
# Getting relevant metadata from PDF file
########################################################################
get_metadata_tags() {

	PDF_Text=$(pdftohtml -stdout -s -i -noframes "${PDF_File}" | html2text)
	if [ -z "$PDF_Text" ];then
		PDF_Text=$(pdftohtml -stdout -s -i -hidden -noframes "${PDF_File}" | html2text)
	fi
	
	scratch1=$(stat -c '%Y' "${PDF_File}")
	PDF_FileMod_Time=$(date -d @"${scratch1}" '+%Y:%m:%d %H:%M:%S%:z')
	scratch2=$(exiftool -T -sep ' ' -Author -Keywords -Subject -Title -CreateDate "${PDF_File}")
	PDF_Author=$(echo "${scratch2}" | awk -F $'\t' '{print $1}')
	PDF_Keywords=$(echo "${scratch2}" | awk -F $'\t' '{print $2}')
	PDF_Subject=$(echo "${scratch2}" | awk -F $'\t' '{print $3}')
	PDF_Title=$(echo "${scratch2//_/ }" | awk -F $'\t' '{print $4}')
	PDF_Create_Time=$(echo "${scratch2}" | awk -F $'\t' '{print $5}' )

}

eval_metadata (){
	
	# check our document metadata against filename metadata
	# if some is empty, copy over
	if [[ -z ${PDF_Create_Time} ]] && [[ ! -z ${PDF_FNCreate_Time} ]];then
		PDF_Create_Time=${PDF_FNCreate_Time}
	fi
	if  [[ -z ${PDF_FNCreate_Time} ]] && [[ ! -z ${PDF_Create_Time} ]];then
		PDF_FNCreate_Time=${PDF_Create_Time}
	fi
    
    
    # only comparing date, since that's all the file tagging keeps
	if [[ `echo "${PDF_FNCreate_Time}" | awk -F ' ' '{print $1}'` != `echo "${PDF_Create_Time}" | awk -F ' ' '{print $1}'` ]];then
		ARGVAL=${PDF_Create_Time}
		FNARGVAL=${PDF_FNCreate_Time}
		if_conflicting_tags
		PDF_Create_Time=${ARGVAL}
		PDF_FNCreate_Time=${ARGVAL}
	 fi   

	if [[ -z ${PDF_Keywords} ]] && [[ ! -z ${PDF_FNTags} ]];then
		PDF_Keywords="${PDF_FNTags}"
	fi
	if  [[ -z ${PDF_FNTags} ]] && [[ ! -z ${PDF_Keywords} ]];then
		PDF_FNTags="${PDF_Keywords}"
	fi
	if [[ "${PDF_FNTags}" != "${PDF_Keywords}" ]];then
		ARGVAL="${PDF_Keywords}"
		FNARGVAL="${PDF_FNTags}"
		if_conflicting_tags
		PDF_Keywords="${ARGVAL}"
		PDF_FNTags="${ARGVAL}"
	 fi   

	
	if [[ -z ${PDF_Title} ]] && [[ ! -z ${PDF_FNTitle} ]];then
		PDF_Title="${PDF_FNTitle}"
	fi
	if  [[ -z ${PDF_FNTitle} ]] && [[ ! -z ${PDF_Title} ]];then
		PDF_FNTitle="${PDF_Title}"
	fi
	if [[ "${PDF_FNTitle}" != "${PDF_Title}" ]];then
		ARGVAL="${PDF_Title}"
		FNARGVAL="${PDF_FNTitle}"
		if_conflicting_tags
		PDF_Title="${ARGVAL}"
		PDF_FNTitle="${ARGVAL}"
	 fi   

}

if_conflicting_tags () {

	#abstracting ARGVAL,FNARGVAL
	if [ "${ARGVAL}" != "${FNARGVAL}" ];then 
		Resolution=$(yad --width=400 --height=200 --center --window-icon=gtk-error \
		--borders 3 --title="Conflicting metadata" --text="Verify conflicting PDF metadata:" \
		--radiolist --list --column=choose:RD --column=metadata:text false "${ARGVAL}" false "${FNARGVAL}" false "manual resolution")
		if [ ! -z "${Resolution}" ];then
			if [[ "${Resolution}" =~ "manual resolution" ]];then
				ResolveString=$(echo "${ARGVAL} ${FNARGVAL}")
				Resolution2=$(yad --form --width=400 --center --window-icon=gtk-info \
				--borders 3 --title="PDF Metadata" --text="Verify and edit PDF metadata:" \
				--field="Edit This String" \
				--button=gtk-cancel:1 --button=gtk-ok:0  \
				"${ResolveString}")
				if [ "$?" == "0" ];then
                    
					ARGVAL=$(echo "${Resolution2}" | awk -F '|' '{print $1}')
					FNARGVAL=$(echo "${Resolution2}"awk -F '|' '{print $1}')            
				fi
			else
				ARGVAL=$(echo "$Resolution" | awk -F '|' '{print $2}')
				FNARGVAL=$(echo "$Resolution" | awk -F '|' '{print $2}')
			fi
		fi
	fi
}

display_metadata () {
	
	#Using the remote server aspect of xpdf to kill it after perusal
	xpdf -remote skipa -geometry 300x400 -bg rgb:10/16/10 -z page "${PDF_File}" &
	
    #https://www.thelinuxrain.com/articles/multiple-item-data-entry-with-yad
	OutString=$(yad --width=400 --center --window-icon=gtk-info \
	--borders 3 --title="PDF Metadata" --text="Verify and edit PDF metadata:" \
	--form --date-format="  %Y:%m:%d %H:%M:%S" --item-separator="," \
	--field="Filename" \
	--field="Title" \
	--field="Subject" \
	--field="Author" \
	--field="Tags" \
	--field="Creation Time":DT \
	--button=gtk-save:0 --button=gtk-cancel:2 --button=gtk-quit:1\
	"${PDF_File}" "${PDF_Title}" "${PDF_Subject}" "${PDF_Author}" "${PDF_Keywords}" "${PDF_Create_Time}" )
	foo=$?
    if [[ "$foo" == "2" ]];then
        xpdf -remote skipa -quit
        rm -rf "$tempdir"
        exit 88  #user 
    fi
	if [[ "$foo" == "0" ]];then
		PDF_File=$(echo "$OutString" | awk -F '|' '{print $1}') 
		PDF_Title=$(echo "$OutString" | awk -F '|' '{print $2}') 
		PDF_FNTitle=$(echo "$OutString" | awk -F '|' '{print $2}')
		PDF_Subject=$(echo "$OutString" | awk -F '|' '{print $3}') 
		PDF_Author=$(echo "$OutString" | awk -F '|' '{print $4}') 
		PDF_Keywords=$(echo "$OutString" | awk -F '|' '{print $5}') 
        PDF_FNTags=$(echo "$OutString" | awk -F '|' '{print $5}')
		PDF_Create_Time=$(echo "$OutString" | awk -F '|' '{print $6}' ) 
	fi 
	
	xpdf -remote skipa -quit
	
}

# Tests particularly for directory checking, but also just because
is_pdf (){
    RETURNVAL=""
    RETURNVAL=$(file "${PDF_File}" | grep -c "PDF document")
    
}

main_loop (){
        get_filename_tags
		get_metadata_tags
		eval_metadata
		display_metadata
		tags_to_filename
    
}

##############################################################################
# Main
##############################################################################

    init_vars
	if [ "$#" = 0 ];then
		echo "Please call this with the filename as the first argument."
	else
        if [ -d "$1" ];then
            for files in $1/*; do
                if [ -f "$files" ];then                   
                    PDF_File="$files"
                    is_pdf
                    if [ $RETURNVAL -gt 0 ];then
                        fullpath=$(readlink -f "$files")
                        PDF_Dir=$(dirname "$fullpath")
                        main_loop
                    fi
                fi
            done                
            exit
        fi
		if [ -f "$1" ];then
			PDF_File="$1"
            is_pdf
            if [ $RETURNVAL -gt 0 ];then
                fullpath=$(readlink -f "$1")
                PDF_Dir=$(dirname "$fullpath")
                main_loop
            fi
		else
			echo "File not found..."
        fi
	fi
    rm -rf "$tempdir"
