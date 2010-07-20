from django.http import HttpResponse
#from django.template import Template, Context
from django.shortcuts import *

import commands
import random

def gene_structure_png(request, *q):
	s, out = commands.getstatusoutput("./exteranal/reneder-gene.pl %s" % q)
	return HttpResponse(out, mimetype='image/png')
	#return HttpResponse(q)

def homepage(request):
	l = []
	for x in range(1,200):
		l.append(random.randint(1, 4591))

	return render_to_response("side-by-side.html", {'sequence_id_list': l})
