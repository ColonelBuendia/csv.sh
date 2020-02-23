#!/bin/sh
#
# csv.sh: basic csv tools concived as an an exercise to determine just how many times
# one human being can try a thousand stack overflow answers for hours on end before
# reading the god damned manuals for ten minutes to find the answer, and
# yet somehow still start at stack overflow again the next time.
# as of now: the world may never know...
#
# Im using ascii 31 record seperator as record seperator in view, lets see how that goes
# idea - https://ronaldduncan.wordpress.com/2009/10/31/text-file-formats-ascii-delimited-text-not-csv-or-tab-delimited-text/
#
# the most relevant thing in the whole world:
# https://www.gnu.org/software/gawk/manual/html_node/Splitting-By-Content.html
#
# tis is hacky but beautiful:
# https://stackoverflow.com/questions/11630092/declaring-an-awk-function-in-bash
#
# also, https://stackoverflow.com/questions/1729824/an-efficient-way-to-transpose-a-file-in-bash

set -e

filename=$(mktemp)
trap "rm -f ${filename}" HUP INT QUIT ILL TRAP KILL BUS TERM

csv2htmlawk=$(
    cat << 'EOF'
BEGIN {
		FPAT = "([^,]*)|(\"[^\"]+\")"
        print "<table>"
}       
 
{
        gsub(/</, "\\&lt;")
        gsub(/>/, "\\&gt;")
        gsub(/&/, "\\&gt;")
        print "\t<tr>"
        for(f = 1; f <= NF; f++)  {
                if(NR == 1 && header) {
                        printf "\t\t<th>%s</th>\n", $f
                }       
                else printf "\t\t<td>%s</td>\n", $f
        }       
        print "\t</tr>"
}       
 
END {
        print "</table>"
}
EOF
)

csvtransposeawk=$(
    cat << 'EOF'
BEGIN { 
		FPAT = "([^,]*)|(\"[^\"]+\")"
		OFS="," 
}
{
    for (rowNr=1;rowNr<=NF;rowNr++) {
        cell[rowNr,NR] = $rowNr
    }
    maxRows = (NF > maxRows ? NF : maxRows)
    maxCols = NR
}
END {
    for (rowNr=1;rowNr<=maxRows;rowNr++) {
        for (colNr=1;colNr<=maxCols;colNr++) {
            printf "%s%s", cell[rowNr,colNr], (colNr < maxCols ? OFS : ORS)
        }
    }
}
EOF
)

if [ -z $1 ]; then
    echo ""
    echo "view         - (g)awk FPAT based viewer with column"
    echo "flatten      - (g)awk FPAT based flatten"
    echo 'tranpose     - (g)awk FPAT based transpose'
    echo 'psuedosqlon1 - search col 1 for lines like $3'
    echo 'stats        - a few quick stats'
    echo "2sc          - basic csv viewer in sc w/ psc"
    echo '2tab         - (g)awk FPAT with OFS as \\t'
    echo '2json        - use python stdlib to convert to json'
    echo '2html        - (g)awk FPAT based html converter'
    echo '2bat         - just pipe into bat for the syntaxy goodness'
    echo ""
    echo "examples:"
    echo "$(basename $0) 2html somefile.csv"
    echo "cat someotherfile.csv | $(basename $0) view"
    echo "$(basename $0) psuedosql file yoursearchtermhere"
    echo "cat somethirdfile.csv | $(basename $0) transpose | $(basename $0) 2html"
    echo ""
    echo "note - if your csv has newlines in the fields, womp womp"
    echo ""
    exit
fi

# my  old way for stdin
# filename=${2:-/dev/stdin}

# stdin or file
# new way i like better, via Dustin Kirkland's calc-stats
if [ -f "$2" ]; then
    cat "$2" > "$filename"
else
    cat /dev/stdin > "$filename"
fi

# Do i care about case? maybe.  to review.
case "$1" in
    view)
        awk -v FPAT='"[^"]*"|[^,]*' -v OFS='␞' '{$1=$1; print $0}' "$filename" |
            column -s␞ -t -n
        ;;
    flatten)
        awk -v FPAT='"[^"]*"|[^,]*' '{for(i=0;i++<NF;)print $i}' "$filename"
        ;;
    transpose)
        awk "$csvtransposeawk" "$filename"
        ;;
    stats)
        # the sed at the end is commafying the line count
        echo "LINES: $(cat "$filename" | wc -l | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')"
        echo ""
        echo "Histogram of fields per line"
        awk -v FPAT='"[^"]*"|[^,]*' '{ print NF ":" $0 } ' "$filename" |
            awk -F: '{ print $1}' |
            sort | uniq -c | sort -rh | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
        ;;
    psuedosql)
        awk -v FPAT='"[^"]*"|[^,]*' -v a="$3" -v IGNORECASE=1 '$1 ~ a {print $0}' "$filename"
        ;;
    2sc)
        if command -v sc > /dev/null 2>&1; then
            cat "$filename" | psc -k -d, | sc
        else
            echo "sc not installed yo"
        fi
        ;;
    2tab)
        awk -v FPAT='"[^"]*"|[^,]*' -v OFS='\t' '{$1=$1; print $0}' "$filename"
        ;;
    2json)
        python -c "import csv,json;print json.dumps(list(csv.reader(open('$filename'))))"
        ;;
    2html)
        awk "$csv2htmlawk" "$filename"
        ;;
    2bat)
        if command -v bat > /dev/null 2>&1; then
            bat -l csv "$filename"
        else
            echo "bat is not installed yo, or not on path, but whatever, you get it"
        fi
        ;;
esac
rm -f "$filename"
