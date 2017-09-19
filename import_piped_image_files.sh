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
    echo "find [options to find files to import] | ${0##*/} [-m] [-d] [-f] [-t target_directory]"
    echo
    echo "***********************************"
    echo "Script needs to be fed (STDIN) with list of files to import: "
    echo "for instance the output from 'find'"
    echo "By default, files will be imported (copied) in '$HOME/Pictures' directory"
    echo "Options:"
    echo " -m move (instead of copy for import). Optional."
    echo " -t target directory. Import files to this target directory. Optional"
    echo " -d debug. BASH debugging. Optional"
    echo " -f force. Import file regardless it exists in target. Optional"
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
    echo "current directory and import (copy) them in default dir: $HOME/Pictures"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 2:"
    echo 'find . -type f -iname "*jpg" -o -name "*CR2" | import_piped_image_files.sh -t otherdir'
    echo
    echo "Same as previous example, but files are imported under 'otherdir' instead"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 3:"
    echo 'find . -newer "last.jpg" -a -name "*CR2" | import_piped_image_files.sh -m -t other_dir'
    echo
    echo "All CR2 files newer than 'last.jpg' found under '.' dir will be imported (moved)"
    echo "under 'other_dir'"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 4:"
    echo 'find . -name "*CR2" | import_piped_image_files.sh -t "dir with spaces"'
    echo
    echo "All CR2 files found under '.' dir will be imported (copied) under 'dir with spaces'"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "EXAMPLE 5:"
    echo 'find . -name "*CR2" | import_piped_image_files.sh -t dir\ with\ spaces'
    echo
    echo "All CR2 files found under '.' dir will be imported (copied) under 'dir with spaces'"
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
    mv
    cp
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

function import_file() {
    #e_echo "function: import_file"
    # import file 
    local a_file[0]="$1"
    local a_target[0]="$2"
    local -n impfile_a_counters=$3
    local -n impfile_binary=$4

    e_echo "INFO: Importing($impfile_binary) ${a_file[0]} to ${a_target[0]}"
    $impfile_binary "${a_file[0]}" "${a_target[0]}" && step_up_counter impfile_a_counters "imported"
}

function check_date() {
    #e_echo "function: check_date"
    local date="$1"
    local -n chdate_a_counters="$2"

    # date non-empty?
    [[ $date != "" ]]
    result="$?"

    [ "$result" -eq 0 ] || { e_echo "WARN: Unable to get Date/Time Original tag from $file file. Skipping it. "; step_up_counter chdate_a_counters "skip_no_date"; }
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
    declare -A splitdate
    local i

    splitdate[year]=$(echo $date | gawk -F":" '{print $1}')
    splitdate[month]=$(echo $date | gawk -F":" '{print $2}')
    splitdate[day]=$(echo $date | gawk -F":" '{print $3}')

    check_year ${splitdate[year]} || { e_echo "ERROR: Year ${splitdate[year]} is not valid. Exiting..."; exit 3;}
    check_month-day ${splitdate[month]} || { e_echo "ERROR: Month ${splitdate[month]} is not valid. Exiting..."; exit 4;}
    check_month-day ${splitdate[day]} || { e_echo "ERROR: Month ${splitdate[day]} is not valid. Exiting..."; exit 5;}

    for i in year month day
    do
        echo "${splitdate[$i]}"
    done

    # it returns YYYY, MM, DD
}
    
function create_folders() {
    #e_echo "function: create_folders"
    # it creates YYYY/MM/DD folder structure 
    # under base directory 
    local year="$1"
    local month="$2"
    local day="$3"
    local a_import_dir[0]="$4"
    local -n createfold_a_counters=$5
    local folders=( "${a_import_dir[0]}/$year" "${a_import_dir[0]}/$year/$month" "$a_import_dir/$year/$month/$day" )


    for folder in "${folders[@]}"
    do
        [[ "$folder" != "" ]] && {
            # debug
            #e_echo "INFO: Checking if $folder folder exists"
            check_not_exists "$folder" && {
                                            step_up_counter createfold_a_counters "dir_needed"
                                            e_echo "INFO: Creating folder $folder"
                                            mkdir "$folder" && step_up_counter createfold_a_counters "dir_created"
                                        }
        }

    done
}

function check_file_in_target() {
    #e_echo "function: check_file_in_target"
    # using array file to prevent errors in filenames with spaces
    local a_file[0]="${1##*/}"
    local a_dir[0]="$2"
    local -n chfit_a_counters="$3"

    #e_echo "INFO: Checking if target file $a_dir/${file[0]} exists..."
    [[ ! -e "$a_dir/${a_file[0]}" ]] 
    result="$?"

    [ "$result" -ne 0 ] && { e_echo "WARN: File $a_dir/${a_file[0]} already exists. Skipping it..."; step_up_counter chfit_a_counters "skip_exist"; }
    return "$result"
}


function store_filenames_in_array() {
    #e_echo "function: store_filenames_in_array"
   # all filenames output by find will be placed in an array: a_files_to_import
    # key is declaring locally the nameref stofilia_a_files_to_import variable to a_files_to_import
    local -n stofilia_a_files_to_import="$1"
    local file
    local i

    i=0
    while read file
    do
        #nameref
        stofilia_a_files_to_import[$((i++))]="$file"
    done
    # debug
    #for file in "${stofilia_a_files_to_import[@]}"
    #do
    #    echo $file
    #done
}

function process_files_to_import() {
    #e_echo "function: process_files_to_import"

    # let's try nameref (local -n) to manipulate arrays
    local -n ptfi_a_files_to_import=$1
    local file
    local -n ptfi_a_import_dir=$2
    local -n pfti_a_counters=$3
    local -n pfti_binary=$4
    local -n pfti_force=$5

    #step_up_counter pfti_a_counters dummy

    # loop over the set of files to import
    for file in "${ptfi_a_files_to_import[@]}"
    do  

        e_echo "INFO: Processing $file"

        local date=$(get_date "$file")
        
        # step-up file read counter
        step_up_counter pfti_a_counters "read"

        check_date "$date" pfti_a_counters || continue
        local yyyymmdd=( $(split_date "$date") )

        local year="${yyyymmdd[0]}"
        local month="${yyyymmdd[1]}"
        local day="${yyyymmdd[2]}"

        create_folders "$year" "$month" "$day" "${ptfi_a_import_dir[@]}" pfti_a_counters

        local target_folder[0]="${ptfi_a_import_dir[0]}/$year/$month/$day"

        if [ $pfti_force == "no" ]
        then
            # import file only if it does NOT exist in target. (no -f switch)
            check_file_in_target "$file" "$target_folder" pfti_a_counters && import_file "$file" "${target_folder[0]}" pfti_a_counters pfti_binary
        else
            # import file even if it exists in target (-f switch given by user)
            import_file "$file" "${target_folder[0]}" pfti_a_counters pfti_binary
        fi

    done
}

function check_if_not_piped() {
    #e_echo check_if_not_piped
    # this function checks if script is fed (piped) from a previous program
    [[ ! -p /dev/stdin ]] && usage
}

function step_up_counter() {
    #e_echo "step_up_counter $2"

    local -n stuc_a_counters="$1"
    local idx="$2"

    (( stuc_a_counters[$idx]++ ))
    
    #debug
    #for i in "${!stuc_a_counters[@]}"
    #do
    #    e_echo "counter(key):  $i ------- value: ${stuc_a_counters[$i]}"
    #done
}

function draw_line() {
    #e_echo draw_line
    local length=$1

    printf -v line '%*s' "$length"
    echo ${line// /-}
    
}

function show_counters() {
    #e_echo show_counters
    local -n showc_a_counters=$1
    local idx
    local length=67

    echo
    draw_line $length
    printf "%-60s: %5d\n" "New folders needed" "${showc_a_counters[dir_needed]}"
    printf "%-60s: %5d\n" "New folders created" "${showc_a_counters[dir_created]}"
    draw_line $length
    printf "%-60s: %5d\n" "Files read" "${showc_a_counters["read"]}"
    printf "%-60s: %5d\n" "Files skipped due to they exist on target" "${showc_a_counters[skip_exist]}"
    printf "%-60s: %5d\n" "Files skipped due to no Date/Time Original tag was found" "${showc_a_counters[skip_no_date]}"
    draw_line $length
    printf "%-60s: %5d\n" "TOTAL FILES IMPORTED" "${showc_a_counters[imported]}"
    draw_line $length
    echo
}

function check_target_dir() {
    #e_echo check_target_dir


    local dir[0]=$1
    local default[0]=$2
    local result
    local exit_code=0
    
    if [ ! -e "$dir" ] 
    then
        if [ "$dir" == "$default" ] 
        then
            result="No target directory provided as argument and default target directory: $dir DOES NOT exist. Please provide an existing dir as argument."
            exit_code=6
        else        
            result="Target directory: $dir DOES NOT exist. Please provide an existing dir as argument."
            exit_code=7
        fi
    else 
    # target dir exists
        if [ ! -r "$dir" ] || [ ! -w "$dir" ] ||  [ ! -x "$dir" ]
        then
            result="Target directory $dir with not rwx permissions. Try: chmod +rwx $dir"
            exit_code=8
        fi
    fi

    [[ $exit_code -gt 0 ]] && { e_echo "$result" ; exit $exit_code; }
}
    
function process_opts() { #e_echo process_opts
    local -n popts_a_target_dir=$1
    shift 1
    local -n popts_binary=$1
    shift 1
    local -n popts_force=$1
    shift 1
    local OPTIND

    while getopts mt:hfd option
    do
        case "$option" in
                m)  
                    # import pictures by moving them from source location
                    popts_binary="mv"
                    ;;
                t)
                    # target directory
                    popts_a_target_dir[0]="$OPTARG"
                    ;;
                f)  # force import of file even if it already exists in target
                    popts_force="yes"
                    ;;
                d)  # debug (BASH)
                    set -x
                    ;;
                h) usage
                    ;;
                *) usage
                    ;;
        esac
    done
    shift $((OPTIND-1)) # Discard the options and sentinel --
}

# main 

function main() {
    #e_echo "function: main"
    local default_dir="$HOME/Pictures"

    # Bash array to store target directory
    local -a a_target_dir

    # Import method (skip if file exists in target)
    local force="no"

    check_if_not_piped

    check_binaries

    # By default, import will be done by copying
    local BIN="cp"

    a_target_dir[0]="$default_dir"
    process_opts a_target_dir BIN force "$@" #|| export BIN="mv"
    e_echo "INFO: BINary used for import: $BIN"


    # if there are arguments, used them to set new import directory
    # if no args, use default import dir: $HOME/Pictures
    e_echo "INFO: Base directory to import pictures: $a_target_dir"

    check_target_dir "${a_target_dir[0]}" "$default_dir"

    # init counters
    # associative array
    local -A a_counters=( [read]=0 [skip_exist]=0 [skip_no_date]=0 [imported]=0 [dir_needed]=0 [dir_created]=0 [dummy]=0)

    # Bash array to store files to import
    local -a a_files_to_import

    # storing filenames in an array allows to process
    # files and dirs with spaces.
    store_filenames_in_array a_files_to_import  #array is passed by reference to function (local -n in function)   
    # https://stackoverflow.com/questions/16461656/bash-how-to-pass-array-as-an-argument-to-a-function

    # same approach to pass by reference the 3 arrays to the function
    process_files_to_import a_files_to_import a_target_dir a_counters BIN force

    # show counters
    show_counters a_counters

    exit 0
}

main "$@"
