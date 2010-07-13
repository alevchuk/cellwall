# Create your views here.
from django.http import HttpResponse

import commands
import random

def gene_structure_png(request, *q):
	s, out = commands.getstatusoutput("./exteranal/reneder-gene.pl %s" % q)
	return HttpResponse(out, mimetype='image/png')
	#return HttpResponse(q)


def homepage(request):
	out = ""
	out += "<table border=0>"

	for x in range(1,200):
		id = random.randint(1, 4591)
		out += "<tr ><td align=center colspan=2>sequence_id %d</td></tr>" % id
		out += "<tr ><td valign=top>"
		out += "<a href=\"http://bioweb.ucr.edu/Cellwall/sequence.pl?action=render_seqview&sequence_locator=sequence_id:%s\">" % id
		out += "<img style=\"padding-right: 2em; padding-bottom: 4em;\" src=\"http://bioweb.ucr.edu/Cellwall/sequence.pl?action=render_seqview&sequence_locator=sequence_id:%s\" />" % id
		out += "</a>"
		out += "</td><td valign=top>"
		out += "<a href=\"/gene-structure/%s.png\">" % id
		out += "<img style=\"padding-bottom: 4em;\" src=\"/gene-structure/%s.png\" />" % id
		out += "</a>"
		out += "</td></tr>"

	out += "</table>"
	return HttpResponse(out)
