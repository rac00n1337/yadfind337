1 #! /bin/sh
    2 # -*- mode: sh -*-
    3 
    4 export find_cmd='@bash -c "run_find %1 %2 %3 %4 %5"'
    5 
    6 export fts=$(mktemp -u --tmpdir find-ts.XXXXXXXX)
    7 export fpipe=$(mktemp -u --tmpdir find.XXXXXXXX)
    8 mkfifo "$fpipe"
    9 
   10 trap "rm -f $fpipe $fts" EXIT
   11 
   12 fkey=$(($RANDOM * $$))
   13 
   14 function run_find
   15 {
   16     echo "6:@disable@"
   17     if [[ $2 != TRUE ]]; then
   18         ARGS="-name '$1'"
   19     else
   20         ARGS="-regex '$1'"
   21     fi
   22     if [[ -n "$4" ]]; then
   23         dt=$(echo "$4" | awk -F. '{printf "%s-%s-%s", $3, $2, $1}')
   24         touch -d "$dt" $fts
   25         ARGS+=" -newer $fts"
   26     fi
   27     if [[ -n "$5" ]]; then
   28         ARGS+=" -exec grep -q -E '$5' {} \;"
   29     fi
   30     ARGS+=" -printf '%p\n%s\n%M\n%TD %TH:%TM\n%u/%g\n'"
   31     echo -e '\f' >> "$fpipe"
   32     eval find "$3" $ARGS >> "$fpipe"
   33     echo "6:$find_cmd"
   34 }
   35 export -f run_find
   36 
   37 exec 3<> $fpipe
   38 
   39 yad --plug="$fkey" --tabnum=1 --form --field=$"Name" '*' --field=$"Use regex:chk" 'no' \
   40     --field=$"Directory:dir" '' --field=$"Newer than:dt" '' \
   41     --field=$"Content" '' --field="yad-search:fbtn" "$find_cmd" &
   42 
   43 yad --plug="$fkey" --tabnum=2 --list --no-markup --dclick-action="xdg-open '%s'" \
   44     --text $"Search results:" --column=$"Name" --column=$"Size:sz" --column=$"Perms" \
   45     --column=$"Date" --column=$"Owner" --search-column=1 --expand-column=1 <&3 &
   46 
   47 yad --paned --key="$fkey" --button="yad-close:1" --width=700 --height=500 \
   48     --title=$"Find files" --window-icon="system-search"
   49 
   50 exec 3>&-