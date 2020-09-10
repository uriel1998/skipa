#!/bin/bash

########################################################################
#	Reading tags from several types of files
#
#   Get tags from metadata
#	Get tags from filename
########################################################################

# Requirements
#pdftohtml
#html2text
#stat
#date
#exiftool


########################################################################
# Definitions - if sourced, these should already be set
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
}

########################################################################
# Getting tags embedded in filename, if possible
# Currently looking for tags from TagSpaces 
# And dates from GScan2PDF 
# NAME-YYYY-MM-DD[TAG TAG TAG].pdf
########################################################################
get_filename_tags (){
   
    baseFN=$(basename ${PDF_File})
    
    #A Decade in Internet Time Symposium on the Dynamics of the Internet and Society, September 2011 - Boyd, Marwick, Boyd - Social Privacy.pdf
    #JOURNAL - AUTHOR - TITLE - YEAR
    
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

########################################################################
# Getting relevant metadata from PDF file
########################################################################
get_metadata_tags() {

    PDF_Text=$(pdftohtml -stdout -s -i -noframes ${PDF_File} | html2text)
    if [ -z "$PDF_Text" ];then
        PDF_Text=$(pdftohtml -stdout -s -i -hidden -noframes ${PDF_File} | html2text)
    fi
    
    scratch1=$(stat -c '%Y' ${PDF_File})
    PDF_FileMod_Time=$(date -d @"${scratch1}" '+%Y:%m:%d %H:%M:%S%:z')
    echo "${scratch1}"
    scratch2=$(exiftool -T -sep ' ' -Author -Keywords -Subject -Title -CreateDate ${PDF_File})
    PDF_Author=$(echo "${scratch2}" | awk -F $'\t' '{print $1}')
    PDF_Keywords=$(echo "${scratch2}" | awk -F $'\t' '{print $2}')
    PDF_Subject=$(echo "${scratch2}" | awk -F $'\t' '{print $3}')
    PDF_Title=$(echo "${scratch2}" | awk -F $'\t' '{print $4}')
    PDF_Create_Time=$(echo "${scratch2}" | awk -F $'\t' '{print $5}')

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

    if [[ -z ${PDF_Keywords} ]] && [[ ! -z ${PDF_FNTags} ]];then
        PDF_Keywords=${PDF_FNTags}
    fi
    if  [[ -z ${PDF_FNTags} ]] && [[ ! -z ${PDF_Keywords} ]];then
        PDF_FNTags=${PDF_Keywords}
    fi
    
    if [[ -z ${PDF_Title} ]] && [[ ! -z ${PDF_FNTitle} ]];then
        PDF_Title=${PDF_FNTitle} 
    fi
    if  [[ -z ${PDF_FNTitle} ]] && [[ ! -z ${PDF_Title} ]];then
        PDF_FNTitle=${PDF_Title}
    fi
    
    
    #TODO: Add in: if conflict, flag it
    
}

display_metadata () {
    
    #Using the remote server aspect of xpdf to kill it after perusal
    xpdf -remote skipa -geometry 300x400 -bg rgb:10/16/10 -z page "${PDF_File}" &
    
    
    #https://www.thelinuxrain.com/articles/multiple-item-data-entry-with-yad
    
    yad --width=400 --title="" --text="Verify and edit PDF metadata:" \
    --form --date-format="+%Y:%m:%d %H:%M:%S%:z" --item-separator="," \
    --field="Filename" \
    --field="Title" \
    --field="FNTitle" \
    --field="Subject" \
    --field="Author" \
    --field="Keywords" \
    --field="Tags" \
    --field="Creation Time":DT \
    --field="FN Creation Time":DT \
    "${PDF_File}" "${PDF_Title}" "${PDF_FNTitle}" "${PDF_Subject}" "${PDF_Author}" "${PDF_Keywords}" "${PDF_FNTags}" "${PDF_Create_Time}" "${PDF_FNCreate_Time}" 
    
    xpdf -remote skipa -quit
    
}

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
    # These should be set already if called from a function
    
    init_vars
    
    if [ "$#" = 0 ];then
        echo "Please call this as a function or with the filename as the first argument."
    else
        if [ -f "$1" ];then
            PDF_File="$1"
        fi
        if [ ! -f "$PDF_File" ];then
            echo "File not found..."
            exit 1
        fi
        SUCCESS=0
        get_filename_tags
        get_metadata_tags
        eval_metadata
        display_metadata
        #do stuff above
        #change the below, obviously
        #output=$(read_vcard)
        if [ $SUCCESS -eq 0 ];then
            # If it gets here, it has to be standalone
                echo "$output"  # output some data
        else
            exit 99
        fi
    fi
fi

