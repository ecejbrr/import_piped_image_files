# import_piped_image_files
Utility to read STDIN files output by "find" and import (move) them to a $HOME/Pictures/YYYY/MM/DD folder

## Usage
Program to process a list of image files piped from find
It imports (moves) them into $HOME/Pictures/YYYY/MM/DD folder:
YYYY: year
MM: month
DD: day 
being YYYY/MM/DD the date of taken shot.

It uses great "exiftool" program to isolate "Date/Time Original" tag and to use the YYYY/MM/DD data to address the destination folder.
If the image file does NOT have that "Date/Time Original" tag, that file will be skipped (and therefore not imported (moved)).



## Example
```
find . -type f -iname "*jpg" -o -name "*CR2" | ./import_piped_image_files.sh
```

## TODO
- ~~Check if image file already exists in target and skip import.~~
- ~~Handle files/folders with spaces.~~
## Known Limitations
- ~~It does NOT work with files/folders containing spaces.~~
