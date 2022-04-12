use strict;
use warnings;
use Getopt::Long;

=head1 Usage

	--snp <file>	        SNP location (format chrosome-site) 
                                    1-1200
				    1-1500

	--bam <file>	       	WGS bam file

=head1 Ideas

       Read mapping orientation based on flag tag
       Read supporting mutant conducting from MD tag (MD:Z:5A2AA4T2GA1C3AA1A4^G0A3^T1T2C13A1G8TC2G3T3G8C13A1C1A39)

=head1 Example

      perl ~/script/SNP.strand.bias.pl --snp ../example/ --bam ../example/

=cut

my( $snp, $bam, $Help );
GetOptions(
	#"flag:s"=>\$flag,
	"snp:s"=>\$snp,
	"bam:s"=>\$bam,
	#"location:n"=>\$location,
	"help"=>\$Help
);

die `pod2text $0` if ( $Help );

print "File\tTotal_reas\tReads_support_mutant\tForward_reads\tReverse_reads\treverse_reads_percentage\n";

open IN1,"$snp" or die "Can't open $snp";#SNP list
while(<IN1>){
	chomp;
	my($chr,$SNP_site)=(split /\-/,$_)[0,1];

	`samtools view $bam $chr:$SNP_site-$SNP_site > $chr.$SNP_site.sam`; #subset of SNP sam file
	
	open IN2,"$chr.$SNP_site.sam" or die "Can't open $chr.$SNP_site.sam";
	my%hash_flag;
	while(<IN2>){
		my$flag_tag=(split /\t/,$_)[1];
		if( exists $hash_flag{$flag_tag} ){
		}
		else{
			my$flag_information=`samtools flags $flag_tag`;
			my($ID,$info)=(split /\t/,$flag_information)[1,2];
			if($info=~m/MREVERSE/){
				$hash_flag{$ID}="forward";
			}
			elsif($info=~m/REVERSE/){
				$hash_flag{$ID}="reverse";
			}
			else{
				$hash_flag{$ID}="forward";
			}
		}
	}

	open IN3,"$chr.$SNP_site.sam" or die "Can't open $chr.$SNP_site.sam";
	my$SNP_location=$SNP_site;
	my$total_reads=0;
	my$reverse=0;
	my$forward=0;
	while(<IN3>){
		chomp;
		$total_reads++;
		my@sam=split /\t/,$_;
		my$align_start=$sam[3];
		my$flag=$sam[1];
		foreach my$tag ( @sam ){
			if( $tag=~m/MD/ ){
				my$MD=(split /:/,$tag)[2];
				my@location=split /(\d+)/,$MD;
				foreach my$locus ( @location ){	
					if( $locus=~m/\d+$/){
						$align_start+=$locus;
						#print "$align_start\t$ARGV[2]\n";
					}
					elsif( $locus=~m/\^/ ){
						$locus=~s/\^//;
						$align_start+=length($locus);
						#print "$align_start\t$ARGV[2]\n";
					}
					elsif( $locus=~m/[A-Z]$/ ){
						#$align_start+=1;
						#print "###$align_start &&  $SNP_location\n";
						if( $align_start eq $SNP_location ){
							if( $hash_flag{$flag}=~m/forward/ ){
								$forward++;
							}
							elsif( $hash_flag{$flag}=~m/reverse/ ){
								$reverse++;
							}
							last;
						}
						$align_start+=1;
						#print "$align_start\t$ARGV[2]\n";
					}	
				}
			}
		}
	}

	my$reads=$reverse+$forward;
	my$percentage;
	if( $reverse >0 ){
		$percentage=$reverse/$reads;
	}
	else{
		$percentage=0;
	}
	$percentage=sprintf("%.3f",$percentage);
	print "$chr:$SNP_site\t$total_reads\t$reads\t$forward\t$reverse\t$percentage\n";
}
