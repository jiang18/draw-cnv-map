use strict;
use GD::Simple;
use GD::Polyline;

#######################################################
# Modify the parameters below to accommodate your data.
our $HeightPixelPerChr=80;              # 
our $PixelPerMegabase=12;               #
our $MegabasePerSegment=30;             # 
our $NumSegment=11;                     # The maximum length of x axis is MegabasePerSegment * NumSegment
our $NumChr=19;                         # Total number of chromosomes
our ($StartPtX,$StartPtY)=(190,20);     # The coordinate of starting point
our ($ImgXlen,$ImgYlen) = (4370,1630);  # The size of the image
our $font_size = 40;                    #
# Modify the parameters above to accommodate your data.
#######################################################
# Look over the annotation to find any modification to be needed.
#######################################################


my $err_msg = qq{
Three arguments needed:
	Tab-separated input file containing two columns (chromosome, length),
	Tab-separated input file containing four columns (CNV chromosome, start, end, type [gain|loss|both]),
	Output file in JPG format.
Example:
	perl draw_cnv_map.pl pig.genome.txt cnv.txt cnv_map.jpg

};

@ARGV == 3 or die $err_msg;

my ($chr_file, $cnv_file, $out_file) = @ARGV;

my $img = GD::Simple ->new($ImgXlen,$ImgYlen);
$img->font('Arial');
$img->fontsize($font_size);
$img->moveTo($StartPtX,$StartPtY);
$img->penSize(1);
$img->fgcolor('black');
my $EndPtY=$StartPtY+$NumChr*$HeightPixelPerChr;
$img->lineTo($StartPtX,$EndPtY);

open (FH,$chr_file) or die "Cannot open $chr_file: $!\n";
$_=<FH>;
my @chr_len;
while(<FH>)
{
	chomp;
	push @chr_len,[(split(/\t| /))[0,1]];
}
close FH;

open (FH,$cnv_file) or die "Cannot open $cnv_file: $!\n";
$_=<FH>;
my %chr_cnvr;
while(<FH>)
{
	chomp;
	my ($chr,$start,$status)=(split(/\t| /,$_))[0,1,-1];
	push @{$chr_cnvr{$chr}},[$start,$status];
}
close FH;

my @chr_len_tmp;
foreach my $i (@chr_len)
{
	my $chr=$i->[0];
	if(grep($_ eq $chr,(keys %chr_cnvr)))
	{
		push @chr_len_tmp,$i;
	}
}
@chr_len=@chr_len_tmp;

for(my $dummyY=$StartPtY;$dummyY<=$EndPtY;$dummyY += $HeightPixelPerChr)
{
	$img->moveTo($StartPtX,$dummyY);
	$img->lineTo($StartPtX-5,$dummyY);
}
my $i=0;
for(my $dummyY=$StartPtY+$HeightPixelPerChr;$dummyY<=$EndPtY;$dummyY += $HeightPixelPerChr)
{
	my $str='Chr'.$chr_len[$i][0].' ';
	my $delta_x= 170;                                   #  Adjust for the positions of y axis labels
	$img->moveTo($StartPtX-$delta_x,$dummyY-$HeightPixelPerChr/4);
	$img->string($str);
	my $height=$dummyY-$HeightPixelPerChr*3/4;
	&addChr($PixelPerMegabase*$chr_len[$i][1]/1e6,$height);
	my $chr=$chr_len[$i][0];
	foreach (@{$chr_cnvr{$chr}})
	{
		my ($start,$status)=@{$_};
		&addPolygon($status,[$StartPtX+$PixelPerMegabase*$start/1e6,$height]);
	}
	$i++;
	$img->fgcolor('black');
}
$img->penSize(1);
$img->moveTo($StartPtX,$EndPtY);
my $EndPtX=$StartPtX+$PixelPerMegabase*$MegabasePerSegment*$NumSegment;
$img->lineTo($EndPtX,$EndPtY);
$i=0;
for(my $dummyX=$StartPtX;$dummyX<=$EndPtX;$dummyX += $PixelPerMegabase*$MegabasePerSegment)
{
	$img->moveTo($dummyX,$EndPtY);
	$img->lineTo($dummyX,$EndPtY+20);
	my $str=$i.'M';
	my $delta_x=$img->stringWidth($str);   #  Adjust for the positions of x axis labels
	$img->moveTo($dummyX-30,$EndPtY+70);   #  Adjust for the positions of x axis labels
	$img->string($str);
	$i += $MegabasePerSegment;
}
$img->moveTo($EndPtX+100,$EndPtY+70);      #  Adjust for the positions of "(bp)"
$img->string(' (bp)');   

######################################################
# Legend start
# Modify the numbers to change the positions of legend
my $delta_y = 40;                          
$EndPtX -= 500;
$StartPtY += 200;
&addPolygon('loss',[$EndPtX+80,$StartPtY]);
$img->moveTo($EndPtX+120,$StartPtY+$delta_y);
$img->fgcolor('black');
$img->string('Loss');

&addPolygon('gain',[$EndPtX+80,$StartPtY+=100]);
$img->moveTo($EndPtX+120,$StartPtY+$delta_y);
$img->fgcolor('black');
$img->string('Gain');

&addPolygon('both',[$EndPtX+80,$StartPtY+=100]);
$img->moveTo($EndPtX+120,$StartPtY+$delta_y);
$img->fgcolor('black');
$img->string('Loss-Gain');
# Legend end
######################################################

open PIC,'>'.$out_file;
binmode PIC;
print PIC $img->jpeg();


sub addChr {
	my ($len,$y)=@_;
	my $x=$StartPtX;
	
	my $polyline = new GD::Polyline;
	$polyline->addPt($x,$y);
	$polyline->addPt($x+$len,$y);
	$polyline->addPt($x+$len,$y+$HeightPixelPerChr/2);
	$polyline->addPt($x,$y+$HeightPixelPerChr/2);
	
	$img->bgcolor('whitesmoke');
	$img->fgcolor('black');
	$img->penSize(1);
	$img->polygon($polyline);
}

sub addPolygon {
	my ($status,$start_pt)=@_;
	my ($x,$y)=@{$start_pt};
	if($status eq 'loss')
	{
		$img->bgcolor('red');
		$img->fgcolor('red');
	}
	elsif($status eq 'gain')
	{
		$img->bgcolor('blue');
		$img->fgcolor('blue');
	}
	elsif($status eq 'both')
	{
		$img->bgcolor('green');
		$img->fgcolor('green');
	}
	
	$img->penSize(5);                 # Check if the pen size needs to be changed.
	$img->moveTo($x,$y);
	$img->lineTo($x,$y+$HeightPixelPerChr/2);
}