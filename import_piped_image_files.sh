#/usr/bin/env bash
# Author: ecejbrr
# Date: 2017-09-13

# Program to process a list of image files piped from find
# It imports (moves) them into $HOME/Pictures/YYYY/MM/DD folder:
# YYYY: year
# MM: month
# DD: day
# being YYYY/MM/DD the date of taken shot.
#
# Example:
# find . -type f -iname "*jpg" -o -name "*CR2" | ./import_piped_image_files.sh



# set home directory for pictures import directory tree
PHOME="$HOME/Pictures"



function e_echo() {
    echo "$1" >&2 
}

function check_bin() {
    local binary="$1"
    #e_echo "Checking $binary"
    [ $(which "$binary") ] || { e_echo "WARNING: Binary $binary not found. Exiting..."; exit 2; }
}

function check_binaries() {
    # Check binaries existence in host
    local binaries="
    exiftool
    sed
    gawk
    cut
    grep
    "
    for bin in $binaries
    do
        check_bin "$bin" 
    done
}

function check_not_writeable() {
    local dir="$1" 
    #e_echo "Checking $dir writeability"
    [[ ! -w "$dir" ]]
}

function check_not_exists() {
    local dir="$1" 
    #e_echo "Checking $dir existence"
    [[ ! -e "$dir" ]]
}

function check_year() {
    local year="$1"
    echo "$year" | grep -q -E "[0-9]{4}"
    return "$?"
}

function check_month-day() {
    local md="$1"
    echo "$md" | grep -q -E "[0-9]{2}"
}

function move_file() {
    # import file 
    local file="$1"
    local target="$2"
    e_echo "Moving $file to $target"
    mv "$file" "$target"
}

function check_date() {
    local date="$1"
    # date non-empty?
    [[ $date != "" ]]
    result="$?"
    [ "$result" -eq 0 ] || e_echo "INFO: Unable to get Date/Time Original tag from $file file. Skipping it. "
    return "$result"
}

function get_date() {
    # from image file, isolate "Date/Time Original" tag(s)
    # grab YYYY:MM:DD value(s)
    # return first
    local file=$1
    exiftool $file | gawk -F"^Date/Time Original *:" '/^Date\/Time Original/{print $2}' | sed -e 's/^ *//; s/ *$//' | cut -d\  -f1 | head -1

}

function split_date() {
    local date=$1
    local splitdate
    splitdate[0]=$(echo $date | gawk -F":" '{print $1}')
    splitdate[1]=$(echo $date | gawk -F":" '{print $2}')
    splitdate[2]=$(echo $date | gawk -F":" '{print $3}')
    #splitdate=( $(echo $date | gawk -F":" '{print $1}') $(echo $date | gawk -F":" '{print $2}') $(echo $date | gawk -F":" '{print $3}') )

    check_year $splitdate[0] || { e_echo "ERROR: Year $splitdate[0] is not valid. Exiting..."; exit 3;}
    check_month-day $splitdate[1] || { e_echo "ERROR: Month $splitdate[1] is not valid. Exiting..."; exit 4;}
    check_month-day $splitdate[2] || { e_echo "ERROR: Month $splitdate[2] is not valid. Exiting..."; exit 5;}

    # return YYYY, MM, DD
    for i in "${splitdate[@]}"
    do
        echo "$i"
    done
}
    
function create_folders() {
    # it creates YYYY/MM/DD folder structure 
    # under base directory $PHOME if it does not exist
    local year="$1"
    local month="$2"
    local day="$3"
    local folders="
    $PHOME/$year
    $PHOME/$year/$month
    $PHOME/$year/$month/$day
    "

    for folder in "$folders"
    do
        # debug
        #e_echo $folder
        check_not_exists $folder && {
                                        e_echo "Creating folder $folder"
                                        mkdir "$folder"
                                    }
    done
}

function check_file_in_target() {
    local file="${1##*/}"
    local dir="$2"
    [[ ! -e "$dir/$file" ]] 
    result="$?"
    [ "$result" -ne 0 ] && e_echo "INFO: File $dir/$file already exists. Skipping it..."
    return "$result"
}

###############################################################################

# main (processing STDIN with file(s) output by "find")

e_echo "INFO: Base directory to import pictures: $PHOME"

check_binaries

while read file
do

    date=$(get_date "$file")
    
    check_date "$date" || continue
    declare -a yyyymmdd=( $(split_date "$date") )

    year="${yyyymmdd[0]}"
    month="${yyyymmdd[1]}"
    day="${yyyymmdd[2]}"

    create_folders "$year" "$month" "$day"

    target_folder="$PHOME/$year/$month/$day"

    check_file_in_target "$file" "$target_folder" && move_file "$file" "$target_folder"

done


exit 0
