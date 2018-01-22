# draw_cnv_map
A Perl script to draw a map of copy number variation (CNV) regions

Look over the annotation in the script to find any modification to be needed for your data.

# Usage
Three arguments needed:  
&nbsp;&nbsp;	Tab-separated input file containing two columns (chromosome, length),  
&nbsp;&nbsp;	Tab-separated input file containing four columns (CNV chromosome, start, end, type [gain|loss|both]),  
&nbsp;&nbsp;	Output file in JPG format.  
Example:  
&nbsp;&nbsp;	perl draw_cnv_map.pl pig.genome.txt cnv.txt cnv_map.jpg  
