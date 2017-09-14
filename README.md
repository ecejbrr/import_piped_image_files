# import_piped_image_files
Utility to read STDIN files output by "find" and import (move) them to a $HOME/Pictures/YYYY/MM/DD folder
Optionally if the script is given a "directory" as argument(s), all arguments will be considered a target directory instead of $HOME/Pictures

## Usage
Program to process a list of image files piped from find
It imports (moves) them into $HOME/Pictures/YYYY/MM/DD folder:
YYYY: year
MM: month
DD: day 
being YYYY/MM/DD the date of taken shot.

It uses great "exiftool" program to isolate "Date/Time Original" tag and to use the YYYY/MM/DD data to address the destination folder.
If the image file does NOT have that "Date/Time Original" tag, that file will be skipped (and therefore not imported (moved)).



## Examples

Import all JPG files (case insensitive) and all CR2 files from current directory downwards.

```
find . -type f -iname "*jpg" -o -name "*CR2" | ./import_piped_image_files.sh
```

Same as previous example, but files are imported under 'other_dir' instead

```
find . -type f -iname "*jpg" -o -name "*CR2" | ./import_piped_image_files.sh other_dir
```

All CR2 files newer than 'last_img.jpg' found under '.' dir will be imported under 'other_dir'

```
find . -newer "last_img.jpg" -a -name "*CR2" | ./import_piped_image_files.sh other_dir
```

## TODO
- ~~Check if image file already exists in target and skip import.~~
- ~~Handle files/folders with spaces.~~

## Known Limitations
- ~~It does NOT work with files/folders containing spaces.~~

## BASH version
- tested under BASH version 4.3.48(1)-release (x86_64-pc-linux-gnu)
