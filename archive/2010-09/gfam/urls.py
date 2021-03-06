from django.conf.urls.defaults import *

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Example:
    # (r'^gfam/', include('gfam.foo.urls')),

    # Uncomment the admin/doc line below and add 'django.contrib.admindocs' 
    # to INSTALLED_APPS to enable admin documentation:
    # (r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    (r'^admin/', include(admin.site.urls)),

    (r'^gene-structure/(.*)\.png', 'navigator.views.gene_structure_png'),
    (r'^gene-structure$', 'navigator.views.sidebyside'),


    (r'^b([0-9]+)/family/(.*)\.fasta', 'navigator.views.family_fasta'),
    (r'^b([0-9]+)/families$', 'navigator.views.families'),

    (r'^method/(.*)', 'navigator.views.method'),
    (r'^methods$', 'navigator.views.methods'),

    #(r'^$', 'navigator.views.homepage'),
    (r'^$', 'navigator.views.builds'),
)
