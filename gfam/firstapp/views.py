# Create your views here.
from django.http import HttpResponse

def png1(request):
	f = file('/home/alevchuk/03-cellwall/gfam/images/t.png')
	x = f.read()
	f.close()
	return HttpResponse(x, mimetype='image/png')
