#/usr/bin/env bash
# Author: ecejbrr
# Date: 2017-09-13


function usage() {
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "USAGE:"
    echo "Assuming you have downloaded import_piped_image_files.sh script with execution "
    echo "permissions in a folder in your PATH (e.g.: /usr/local/bin)"
    echo
    echo "script_outputting_files_to_import | ${0##*/} [import_directory]"
    echo
    echo "***********************************"
    echo "Script needs to be fed (STDIN) with list of files to import: "
    echo "for instance the output from 'find'"
    echo "By default, files will be imported in '$HOME/Pictures' directory"
    echo "Script optionally accepts a directory as argument. If given it will be used "
    echo "as target base directory"
    echo "The folder structure to place the files under the base import directory is:"
    echo "BASE_IMPORT_DIR/YYYY/MM/DD/picture_file"
    echo "YYYY: year, MM: month, DD: day of the taken shot"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 1:"
    echo
    echo 'find . -type f -iname "*jpg" -o -name "*CR2" | import_piped_image_files.sh'
    echo
    echo "It searchs all JPG case insensitive files and CR2 files from"
    echo "current directory and import them in default dir: $HOME/Pictures"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 2:"
    echo 'find . -type f -iname "*jpg" -o -name "*CR2" | import_piped_image_files.sh other_dir'
    echo
    echo "Same as previous example, but files are imported under 'other_dir' instead"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 3:"
    echo 'find . -newer "last_img.jpg" -a -name "*CR2" | import_piped_image_files.sh other_dir'
    echo
    echo "All CR2 files newer than 'last_img.jpg' found under '.' dir will be imported "
    echo "under 'other_dir'"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 4:"
    echo 'find . -name "*CR2" | import_piped_image_files.sh "dir with spaces"'
    echo
    echo "All CR2 files found under '.' dir will be imported under 'dir with spaces'"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 5:"
    echo 'find . -name "*CR2" | import_piped_image_files.sh dir\ with\ spaces'
    echo
    echo "All CR2 files found under '.' dir will be imported under 'dir with spaces'"
    echo
    echo "--------------------------------------------------------------------------------------"
    
    exit 254
}

function e_echo() {
    echo "$1" >&2 
}

function check_bin() {
    #e_echo "function: check_bin"
    local binary="$1"

    #e_echo "Checking $binary"
    [ $(which "$binary") ] || { e_echo "WARNING: Binary $binary not found. Exiting..."; exit 2; }
}

function check_binaries() {
    #e_echo "function: check_binaries"
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
    #e_echo "function: check_not_writeable"
    local a_dir[0]="$1" 

    #e_echo "Checking $dir writeability"
    [[ ! -w "${a_dir[0]}" ]]
}

function check_not_exists() {
    #e_echo "function: check_not_exists"
    local a_dir[0]="$1" 

    #e_echo "Checking $a_dir[0] existence"
    [[ ! -e "${a_dir[0]}" ]]
}

function check_year() {
    #e_echo "function: check_year"
    local year="$1"

    echo "$year" | grep -q -E "[0-9]{4}"
    return "$?"
}

function check_month-day() {
    #e_echo "function: check_month-day"
    local md="$1"

    echo "$md" | grep -q -E "[0-9]{2}"
}

function move_file() {
    #e_echo "function: move_file"
    # import file 
    local a_file[0]="$1"
    local a_target[0]="$2"

    e_echo "Moving ${a_file[0]} to ${a_target[0]}"
    mv "${a_file[0]}" "${a_target[0]}"
}

function check_date() {
    #e_echo "function: check_date"
    local date="$1"

    # date non-empty?
    [[ $date != "" ]]
    result="$?"

    [ "$result" -eq 0 ] || e_echo "INFO: Unable to get Date/Time Original tag from $file file. Skipping it. "
    return "$result"
}

function get_date() {
    #e_echo "function: get_date"
    # from image file, isolate "Date/Time Original" tag(s)
    # grab YYYY:MM:DD value(s)
    # return first

    # using array file to prevent errors if filename contains spaces
    local a_file[0]="$1"

    exiftool "${a_file[0]}" | gawk -F"^Date/Time Original *:" '/^Date\/Time Original/{print $2}' | sed -e 's/^ *//; s/ *$//' | cut -d\  -f1 | head -1

}

function split_date() {
    #e_echo "function: split_date"
    local date="$1"
    local splitdate

    splitdate[0]=$(echo $date | gawk -F":" '{print $1}')
    splitdate[1]=$(echo $date | gawk -F":" '{print $2}')
    splitdate[2]=$(echo $date | gawk -F":" '{print $3}')
    #splitdate=( $(echo $date | gawk -F":" '{print $1}') $(echo $date | gawk -F":" '{print $2}') $(echo $date | gawk -F":" '{print $3}') )

    check_year $splitdate[0] || { e_echo "ERROR: Year $splitdate[0] is not valid. Exiting..."; exit 3;}
    check_month-day $splitdate[1] || { e_echo "ERROR: Month $splitdate[1] is not valid. Exiting..."; exit 4;}
    check_month-day $splitdate[2] || { e_echo "ERROR: Month $splitdate[2] is not valid. Exiting..."; exit 5;}

    for i in "${splitdate[@]}"
    do
        echo "$i"
    done

    # it returns YYYY, MM, DD
}
    
function create_folders() {
    #e_echo "function: create_folders"
    # it creates YYYY/MM/DD folder structure 
    # under base directory $PHOME if it does not exist
    local year="$1"
    local month="$2"
    local day="$3"
    local a_import_dir[0]="$4"
    local folders="
    ${a_import_dir[0]}/$year
    ${a_import_dir[0]}/$year/$month
    $a_import_dir/$year/$month/$day
    "

    echo "$folders" | while read folder
    do
        [[ "$folder" != "" ]] && {
            # debug
            #e_echo "INFO: Checking if $folder folder exists"
            check_not_exists $folder && {
                                            e_echo "INFO: Creating folder $folder"
                                            mkdir "$folder"
                                        }
        }
    done
}

function check_file_in_target() {
    #e_echo "function: check_file_in_target"
    # using array file to prevent errors in filenames with spaces
    local a_file[0]="${1##*/}"
    local a_dir[0]="$2"

    #e_echo "INFO: Checking if target file $a_dir/${file[0]} exists..."
    [[ ! -e "$a_dir/${a_file[0]}" ]] 
    result="$?"

    [ "$result" -ne 0 ] && e_echo "INFO: File $a_dir/${a_file[0]} already exists. Skipping it..."
    return "$result"
}


function store_filenames_in_array() {
    #e_echo "function: store_filenames_in_array"
    # all filenames output by find will be placed in an array: a_files_to_import
    # key is declaring locally the nameref a_nameref_files_to_import variable to a_files_to_import
    local -n a_nameref_files_to_import="$1"
    local file
    local i

    i=0
    while read file
    do
        #nameref
        a_nameref_files_to_import[$((i++))]="$file"
    done
    # debug
    #for file in "${a_nameref_files_to_import[@]}"
    #do
    #    echo $file
    #done
}

function process_files_to_import() {
    #e_echo "function: process_files_to_import"

    # let's try nameref (local -n) to manipulate arrays
    local -n a_files="$1"
    local file
    local -n a_import_dir="$2"

    # loop over the set of files to import
    for file in "${a_files[@]}"
    do  

        local date=$(get_date "$file")
        
        check_date "$date" || continue
        local yyyymmdd=( $(split_date "$date") )

        local year="${yyyymmdd[0]}"
        local month="${yyyymmdd[1]}"
        local day="${yyyymmdd[2]}"

        create_folders "$year" "$month" "$day" "${a_import_dir[@]}"

        local target_folder[0]="${a_import_dir[0]}/$year/$month/$day"

        check_file_in_target "$file" "$target_folder" && move_file "$file" "${target_folder[0]}"

    done
}

function check_args() {
    #e_echo "function: check_args"
    local args[0]="$1" 

    [[ ${args} != "" ]]

    
    # returns 0 if there are any arguments
}

function check_if_not_piped() {
    #e_echo check_if_not_piped
    # this function checks if script is fed (piped) from a previous program
    [[ ! -p /dev/stdin ]] && usage
}


# main 

function main() {
    #e_echo "function: main"
    # if an argument is found, it will be used as target directory
    local args[0]="$1"
    
    check_if_not_piped

    check_binaries

    # Bash array to store target directory
    declare -a a_target_dir

    # if there are arguments, used them to set new import directory
    # if no args, use default import dir: $HOME/Pictures
    check_args "${args[0]}" && a_target_dir[0]="$args" || a_target_dir[0]="$HOME/Pictures"
    e_echo "INFO: Base directory to import pictures: $a_target_dir"

    # Bash array to store files to import
    declare -a a_files_to_import

    # storing filenames in an array allows to process
    # files and dirs with spaces.
    store_filenames_in_array a_files_to_import  #array is passed by reference to function (local -n in function)   
    # https://stackoverflow.com/questions/16461656/bash-how-to-pass-array-as-an-argument-to-a-function

    # same approach to pass by reference the 2 arrays to the function
    process_files_to_import a_files_to_import a_target_dir

    exit 0
}

main "$@"
