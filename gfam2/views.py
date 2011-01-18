from django.template.loader import get_template
from django.template import Context
from django.http import Http404, HttpResponse
from django.shortcuts import render_to_response

ALIGNMENTS_URL_PREFIX = \
  "http://biocluster.ucr.edu/~alevchuk/sasha/020-sasha/examples" #to Alignment page

families_data = {
     'S1K': {'name': 'Sugar 1-kiases', },
     'UGP': {'name': 'UDP-glucose pyrophosphorylases', },
     'GMP': {'name': 'GDP-mannose pyrophosphorylase', },
   }

tree_data = {
     'S1K': {'tree': 'S1K tree image', },
     'UGP': {'tree': 'UDP-tree image', },
     'GMP': {'tree': 'GDP-tree image', },
   }

structure_data = {
  'structure': {
     'At1g02000': 'GAE2',
     'At1g08200': 'AXS2',
     'At1g12780': 'UGE1',
   },
} 

members_data = {
  'S1K': 
    {
      'At1g02000': {
          'name': 'GAE2',
          'species': 'Arabidopsis thaliana',
          'description': 'NAD-dependent epimerase/dehydratase family protein'},
         
       'At1g08200': {
          'name': 'AXS2',
          'species': 'Arabidopsis thaliana',
          'description': 'expressed protein'},
    },

  'GMP':
    {
      'At1g12780': {
         'name': 'UGE1',
         'length': '1781',
         'fullname': 'UDP-D-GLUCURONATE 4-EPIMERASE 2',
         'structure': 'Image of GAE2 gene structure',
         'sequence': 'AGAAAGGAAAGGAAAGAAAGAAAACAAAAG',
         'species': 'Arabidopsis thaliana',
         'description': 'UDP-glucose ' + \
           '4-epimerase/UDP-galactose 4-epimerase/Galactowaldenase'},
    },

  'UGP':
    {
    },
} 

gene_to_family_data = {
  'At1g12780': ['GMP'],
  'At1234567': [],
  'At1g08200': ['S1K', 'NSI'],
  'At1g02000': ['S1K', 'NSI'],
}

gene_data = {
  'At1g02000': {
      'name': 'GAE2',
      'length': '1781',
      'fullname': 'UDP-D-GLUCURONATE 4-EPIMERASE 2',
      'structure': 'Image of GAE2 gene structure',
      'sequence': 'AGAAAGGAAAGGAAAGAAAGAAAACAAAAG',
      'species':  'Arabidopsis thaliana',
      'description': 'UDP-glucose ' + \
           '4-epimerase/UDP-galactose 4-epimerase/Galactowaldenase',
#      'Features': '''1..1781	
#			/GO="ID: 0003824; Type: function; catalytic activity"
#   		/GO="ID: 0009225; Type: process; nucleotide-sugar metabolism"
#  		/chromosome="1"
#   		/clone="68414"
#   		/clone_name="CHR1v01212004"
#   		/end3="347592"
#   		/end5="345812"
#   		/strand="positive"''',
#     'MODEL': '''241..1545	
#   		/cdna_support="DBXRef: GSLTFB23ZC03; 
#   			-Matching gene and cDNA alignment are identical."''',
#     'EXON': '''1..1781	
#   		/model="68414.m00118"''',
#     'CDS': '''241..1545	
#   		/PFAM="39..129 PseudoU_synth_1 8.9 tRNA pseudouridine synthase"
#   		/PFAM="52..143 MerE 2.3 MerE protein"''',
#     'LEFT_UTR': '''1..240	
#   		/model="68414.m00118"''',
#     'RIGHT_UTR': '''1546..1781	
#   		/model="68414.m00118"''',
   },
}

dna_data = {
  'At1g02000.1': {	 
      'structure': 'GAE2',#an image, diff. from 'gene' page
      'sequence': 'MSHLDDIPSTPGKFKMMDKSPFFLHRTRWQ',
      'features': '''PFAM	39..129	
                     /description="tRNA pseudouridine synthase"
                     /evalue="8.9"
                     /family="PseudoU_synth_1"
                     PFAM	52..143	
                     /description="MerE protein"
                     /evalue="2.3"
                     /family="MerE"''',
   },
} 
 
def families(request):

    t = get_template('families.html')
    html = t.render(Context({'families': families_data}))
    return HttpResponse(html)

def summary(request, abbrev):

    t = get_template('summary.html')
    html = t.render(Context({
                             'ALIGNMENTS_URL_PREFIX': ALIGNMENTS_URL_PREFIX,
                             'families': families_data,
                             'members': members_data[abbrev],
                             'FamilyName': families_data[abbrev]['name'],
                             'FamilyAbbrev': abbrev,
                             },
                   ))
    return HttpResponse(html)

def tree(request, abbrev):
 
    t = get_template('tree.html')
    html = t.render(Context({
                             'ALIGNMENTS_URL_PREFIX': ALIGNMENTS_URL_PREFIX,
                             'families': families_data,
                             'FamilyName': families_data[abbrev]['name'],
                             'FamilyAbbrev': abbrev,
                             'FamilyTree': tree_data[abbrev]['tree'],
			     },
                   ))
    return HttpResponse(html)

def structure(request, abbrev):

    t = get_template('structure.html')
    html = t.render(Context({
                             'ALIGNMENTS_URL_PREFIX': ALIGNMENTS_URL_PREFIX,
                             'families': families_data,
                             'members': members_data[abbrev],
                             'FamilyName': families_data[abbrev]['name'],
                             'FamilyAbbrev': abbrev,
			     },
                   ))
    return HttpResponse(html)

def gene(request, geneid, protein_or_dna):

    if protein_or_dna != "" and \
        protein_or_dna != "protein" and \
        protein_or_dna != "dna":
      raise NameError("Gene must be Protein or DNA. Instead got: %s" %
        protein_or_dna)

    if protein_or_dna == "dna":
    	print "DNA\n"
    else:
    	print "Protein\n"

    t = get_template('gene.html')
    html = t.render(Context({
                             'gene': gene_data,
                             'GeneID': geneid,
                             'GeneName': gene_data[geneid]['name'],
                             'families_data': families_data,
                             'families_for_this_gene': 
                               gene_to_family_data[geneid],
                             'members': members_data,
                             },
                   ))
    return HttpResponse(html)
