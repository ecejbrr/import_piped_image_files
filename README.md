# import_piped_image_files

- Utility to read STDIN files output by ``find`` and import (move) them to a $HOME/Pictures/YYYY/MM/DD folder
- Optionally if the script is given a "directory" as argument(s), all arguments will be considered as the target directory instead of $HOME/Pictures

- Image files will be placed under the target directory in a YYYY/MM/DD folder structure:
 - YYYY: year
 - MM: month
 - DD: day 
 - being YYYY/MM/DD the date of taken shot.

- If the YYYY/MM/DD folder does not exist, it will be created

It uses great ``exiftool`` program to isolate "Date/Time Original" tag and to use the YYYY/MM/DD data to address the destination folder.
If the image file does NOT have that "Date/Time Original" tag, that file will be skipped (and therefore not imported (moved)).



## Examples

Assuming you have downloaded ``import_piped_image_files.sh`` script with execution permissions in a folder in your PATH (e.g.: /usr/local/bin)

Import all JPG files (case insensitive) and all CR2 files from current directory downwards.

```
find . -type f -iname "*jpg" -o -name "*CR2" | import_piped_image_files.sh
```

Same as previous example, but files are imported under 'other_dir' instead

```
find . -type f -iname "*jpg" -o -name "*CR2" | import_piped_image_files.sh other_dir
```

All CR2 files newer than 'last_img.jpg' found under '.' dir will be imported under 'other_dir'

```
find . -newer "last_img.jpg" -a -name "*CR2" | import_piped_image_files.sh other_dir
```

## TODO
- ~~Check if image file already exists in target and skip import.~~
- ~~Handle files/folders with spaces.~~

## Known Limitations
- ~~It does NOT work with files/folders containing spaces.~~

## BASH version
- tested under BASH version 4.3.48(1)-release (x86_64-pc-linux-gnu)
