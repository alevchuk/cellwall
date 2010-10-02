from django.http import HttpResponse
#from django.template import Template, Context
from django.shortcuts import *

import commands
import random

def homepage(request):
	return HttpResponseRedirect("/families")

def gene_structure_png(request, *q):
	s, out = commands.getstatusoutput("./exteranal/reneder-gene.pl %s" % q)
	return HttpResponse(out, mimetype='image/png')
	#return HttpResponse(q)

def sidebyside(request):
	l = []
	#for x in range(1,200):
	#	l.append(random.randint(1, 4591))
	l.append(3195)
	l.append(3135)

	return render_to_response("side-by-side.html", {'sequence_id_list': l})

def family_fasta(request, *q):
        instance_node_id = int(q[0])
	from django.db import connection, transaction
	cursor = connection.cursor()
	cursor.execute("SELECT fasta_line FROM gfam.family_fasta " +
	  "WHERE instance_node_id = %s", [instance_node_id])

	rows = cursor.fetchall()
	return HttpResponse(''.join(f[0] for f in rows), mimetype='text/plain')


def families(request):
	from django.db import connection, transaction
	cursor = connection.cursor()
	# cursor.execute("SELECT instance_node_id FROM gfam.family_fasta " +
	#   "GROUP BY instance_node_id")
        keys = ["instance_node_id",
                "preorder_code",
 		"family_tree_node_abrev",
		"family_tree_node_name"]


	# TODO: Re-write with "WHERE family_tree_id = 1"
	rows = cursor.execute("SELECT " + ",".join(keys) + " FROM " +
         "gfam.family_tree_instance JOIN gfam.family_tree_node ON " +
           "gfam.family_tree_instance.family_tree_node_id = " +
	   "gfam.family_tree_node.family_tree_node_id " +
         "WHERE instance_node_id IN " +
	   "(SELECT instance_node_id FROM " + 
	   "gfam.family_fasta GROUP BY instance_node_id);")

        rows = cursor.fetchall()

        fam_dicts = []
 	for row in rows:
		fam_dict = {}
		for i, key in enumerate(keys):
			fam_dict[key] = row[i]
	        fam_dicts.append(fam_dict)

	return render_to_response("families.html", {'families': fam_dicts})
