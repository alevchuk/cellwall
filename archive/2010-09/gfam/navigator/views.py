from django.http import HttpResponse
#from django.template import Template, Context
from django.shortcuts import *

import commands
import random

# Django style DB access
from navigator.models import *

# Advanced DB access (SQL)
from django.db import connection, transaction


def homepage(request):
	return HttpResponseRedirect("/families")

def builds(request):
	data = []
	for b in FamilyBuild.objects.all():
		d = {}
		d['build_id'] = b.family_build_id
		d['timestamp'] = b.family_build_timestamp
		d['method_id'] = b.family_build_method.family_build_method_id
		d['method'] = b.family_build_method.family_build_method_name
		data.append(d)

	return render_to_response("builds.html", {'data': data})

def method(request, *q):
	method_id = int(q[0])
	m = FamilyBuildMethod.objects.get(family_build_method_id=method_id)
	data = {}
        data['name'] = m.family_build_method_name
	data['builds'] = []
        for i in FamilyBuild.objects.filter(family_build_method=method_id):
		data['builds'].append(i.family_build_id)
	return render_to_response("method.html", {'data': data})



def families(request, *q):
	build_id = int(q[0])

        for tree_instance in FamilyMember.objects.raw(
	  'SELECT instance_node_id ' +
          'FROM gfam.family_member ' +
          'WHERE family_build_id = %s GROUP BY instance_node_id', [build_id]):
		pass #tree_instance.family_tree_node



	# cursor = connection.cursor()
	# # cursor.execute("SELECT instance_node_id FROM gfam.family_fasta " +
	# #   "GROUP BY instance_node_id")
        # keys = ["instance_node_id",
        #         "preorder_code",
 	# 	"family_tree_node_abrev",
	# 	"family_tree_node_name"]


	# # TODO: Re-write with "WHERE family_tree_id = 1"
	# rows = cursor.execute("SELECT " + ",".join(keys) + " FROM " +
        #  "gfam.family_tree_instance JOIN gfam.family_tree_node ON " +
        #    "gfam.family_tree_instance.family_tree_node_id = " +
	#    "gfam.family_tree_node.family_tree_node_id " +
        #  "WHERE " +
        #    "instance_node_id IN " +
	#    "(SELECT instance_node_id FROM " + 
	#    "gfam.family_fasta GROUP BY instance_node_id);")

        # rows = cursor.fetchall()

        fam_dicts = []
 	for row in rows:
		fam_dict = {}
		for i, key in enumerate(keys):
			fam_dict[key] = row[i]
	        fam_dicts.append(fam_dict)

	return render_to_response("families.html", {'families': fam_dicts})


def family_fasta(request, *q):
        instance_node_id = int(q[0])
	cursor = connection.cursor()
	cursor.execute("SELECT fasta_line FROM gfam.family_fasta " +
	  "WHERE instance_node_id = %s", [instance_node_id])

	rows = cursor.fetchall()
	return HttpResponse(''.join(f[0] for f in rows), mimetype='text/plain')


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
