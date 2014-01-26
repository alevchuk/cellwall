from django.conf.urls.defaults import *
import os.path

from gfam2.views import *

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

urlpatterns = patterns('',
    # Example:
    # (r'^cellwall/', include('cellwall.foo.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # (r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    # (r'^admin/', include(admin.site.urls)),
    
    (r'^/?$', families),
    (r'^families/?$', families),
    (r'^summary/([a-z,A-Z,0-9]*)$', summary),
    (r'^tree/([a-z,A-Z,0-9]*)$', tree),
    (r'^structure/([a-z,A-Z,0-9]*)$', structure),

    (r'^([a-z,A-Z,0-9,.]*)()$', gene), # Default is protein
    (r'^([a-z,A-Z,0-9]*)/(protein)$', gene),
    (r'^([a-z,A-Z,0-9]*)/(dna)$', gene),
)
