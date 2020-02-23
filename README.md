# csv.sh
yet another csv parser
Uses only things that are pre-installed on all machines I interact with regularly. In practice 90% awk.  


view         - (g)awk FPAT based viewer with column  
flatten      - (g)awk FPAT based flatten  
tranpose     - (g)awk FPAT based transpose  
psuedosqlon1 - search col 1 for lines like $3  
stats        - a few quick stats  
2sc          - basic csv viewer in sc w/ psc  
2tab         - (g)awk FPAT with OFS as \t  
2json        - use python stdlib to convert to json  
2html        - (g)awk FPAT based html converter  
2bat         - just pipe into bat for the syntaxy goodness  


examples:  
$(basename $0) 2html somefile.csv  
cat someotherfile.csv | $(basename $0) view  
$(basename $0) psuedosql file yoursearchtermhere  
cat somethirdfile.csv | $(basename $0) transpose | $(basename $0) 2html  
     
note - if your csv has newlines in the fields, womp womp  
