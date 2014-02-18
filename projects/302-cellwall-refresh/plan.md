<pre>
1.1 pick the smallest family: fam_x                     ===> GH43 (11 peptides) <a href="http://biocluster.ucr.edu/~alevchuk/cellwall-refresh/data/110-one-family/gh43.fasta">gh43.fasta</a>
1.2 download latest uniprot                             ===> Uniprot 2014-01 (50 million sequences) <a href="http://biocluster.ucr.edu/~alevchuk/cellwall-refresh/data/120-download-uniprot/">data</a>
1.3 build an msa from fam_x                             ===> Used MAFFT <a href="http://biocluster.ucr.edu/~alevchuk/cellwall-refresh/data/130-build-msa/gh43/MSA.MAFFT.Guidance_res_pair_res.html">MSA visualiztion</a>

2.1 remove bad sequences with one of:                   ===> Used GUIDANCE. No bad sequences were removed from GH43.
   * GUIDANCE latest version (v1.4.1, 2013, Dec)
   * or my ms thesis enhanced GUIDANCE method
   * or blast all-against-all
2.2 re-align msa                                        ===> Unnecessary because in 2.1 bad sequences not removed.
2.3 build an hmm from the msa                           ===> <a href="http://biocluster.ucr.edu/~alevchuk/cellwall-refresh/data/230-build-hmm/gh43.hmm">hmm</a>
2.4 find matches in uniprot for the hmm (-E 0.1)        ===> 3243 peptides found for GH43 <a href="http://biocluster.ucr.edu/~alevchuk/cellwall-refresh/data/240-find-matches-in-uniprot/">Uniprot hits</a>
2.5 add matches to fam_x
2.6 re-align msa

In my ec2 instance of cellwall web ui:
--------------------------------
3.1 refresh flat-files for fam_x
3.2 refresh mysql data for fam_x
--------------------------------

In production:
-----------------------------------------------------
4.1 apply the same changes to http://cellwall.ucr.edu
-----------------------------------------------------

5.1 repeat all of the steps above for the next family

6.1 if a family is too big, discuss a splitting it
</pre>
