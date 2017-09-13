#/usr/bin/env bash
# Author: ecejbrr
# Date: 2017-09-13

# Program to process a list of image files piped from find
# It places (moves) them into $HOME/Pictures/YYYY/MM/DD folder:
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
    echo $1 >&2 
}

function check_bin() {
    local binary=$1
    #e_echo "Checking $binary"
    [ $(which $binary) ] || { e_echo "Binary $binary not found. Exiting..."; exit 2; }
}

function check_not_writeable() {
    local dir=$1 
    #e_echo "Checking $dir writeability"
    [[ ! -w $dir ]]
}

function check_not_exists() {
    local dir=$1 
    #e_echo "Checking $dir existence"
    [[ ! -e $dir ]]
}

function check_year() {
    local year=$1
    echo $year | grep -q -E "[0-9]{4}"
    return $?
}

function check_month-day() {
    local md=$1
    echo $md | grep -q -E "[0-9]{2}"
}

function move_file() {
    local file=$1
    local target=$2
    e_echo "Moving $file to $target"
    mv $file $target
}

function check_date() {
    local date=$1
    [[ $date == "" ]]
}

# main (processing STDIN with file(s) output by "find")

e_echo "Home folder to create directory structure: $PHOME"

# Check binaries
binaries="
exiftool
sed
gawk
cut
grep
"
for bin in $binaries
do
    check_bin $bin 
done

while read file
do

    # grab taken shot date (YYYY:MM:DD) from image file
    date=$(exiftool $file | gawk -F"^Date/Time Original *:" '/^Date\/Time Original/{print $2}' | sed -e 's/^ *//; s/ *$//' | cut -d\  -f1 | sort -u)
    #e_echo "date: $date"
    
    check_date $date && { e_echo "Unable to get Date/Time Original tag from $file file. Skipping it. "; continue; }

    year=$(echo $date | gawk -F":" '{print $1}')
    check_year $year || { e_echo "Year $year is not valid. Exiting..."; exit 3;}

    month=$(echo $date | gawk -F":" '{print $2}')
    check_month-day $month || { e_echo "Month $month is not valid. Exiting..."; exit 4;}

    day=$(echo $date | gawk -F":" '{print $3}')
    check_month-day $day || { e_echo "Day $day is not valid. Exiting..."; exit 5;}


    # create folder tree if it does not exist
    folders="
    $PHOME/$year
    $PHOME/$year/$month
    $PHOME/$year/$month/$day
    "
    for folder in $folders
    do
        check_not_exists $folder && { 
                                        e_echo "Creating folder $folder" 
                                        mkdir $folder
                                    }
    done

    # check target folder writeability permissions
    folders="
    $PHOME
    $PHOME/$year
    $PHOME/$year/$month
    $PHOME/$year/$month/$day
    "
    for folder in $folders
    do
        check_not_writeable $folder && { e_echo "$folder is not writable. Fix it." ; exit 1 ; }
    done

    target_folder="$PHOME/$year/$month/$day"
    # move picture file
    move_file $file $target_folder

done


exit 0
