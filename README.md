Usage:

perl SNP.strand.bias.loop.pl --bam sample96.subset.sorted.bam --snp somatic.01.subset.ID > output.txt

Concept:

MD tag in bam/sam file was used to determine whether read support mutant. ( such as: MD:Z:5A2AA4T2GA1C3AA1A4^G0A3^T1T2C13A1G8TC2G3T3G8C13A1C1A39)

Flag tag in bam/sam file was used to determine the orientation of read mapping (such as: samtools flags 64)
