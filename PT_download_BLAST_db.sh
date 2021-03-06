#!/bin/bash
#$ -cwd
set -euo pipefail
# script to convert donwload NR

cd /shelf/public/blastntnr/blastDatabases

rm -rf prot.accession2taxid.gz.md5 prot.accession2taxid.gz *.dmp taxcat.zip taxdump.tar.gz nr.faa taxdb.*

# get the accession to txid db
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz.md5
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz
md5sum -c prot.accession2taxid.gz.md5
pigz -d prot.accession2taxid.gz

# get the tax id files
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxcat.zip
unzip -o taxcat.zip

# download the tx id database. Yes yet more files
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz

# get the tax dump files
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
#tar -zxvf taxdump.tar.gz

# download human genomic
perl update_blastdb.pl --passive --force human_genomic

# download nr
perl update_blastdb.pl --passive --force blastdb nr

# download nt
perl update_blastdb.pl --passive --force blastdb nt

# download swissprot
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz

folders=*.tar.gz
for folder in ${folders}
do
    tar -zxvf ${folder}
done


export BLASTDB=/shelf/public/blastntnr/blastDatabases

# diamond can only use protein databases with this program.
blastdbcmd -entry 'all' -db nr > nr.faa

echo "im making the nr fasta file"

# load diamond v0.7.11.60
module load diamond
diamond makedb --in nr.faa -d nr

echo "nr fasta done"
pigz -d uniprot_sprot.fasta.gz 
diamond makedb --in uniprot_sprot.fasta -d uniprot

#diamond makedb --in /mnt/shared/cluster/blast/ncbi/extracteduniref90.faa -d uniref90


#files required for pyhon script to get tax id and species name ..


echo "downloading and unzipping done"
pigz -d prot.accession2taxid.gz

python prepare_accession_to_description_db.py

echo "four discription to accession number database done"

pigz prot.accession2taxid

echo "deleting nr.faa"
rm nr.faa
echo "finished"
