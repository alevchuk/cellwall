# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#     * Rearrange models' order
#     * Make sure each model has one field with primary_key=True
# Feel free to rename the models, but don't rename db_table values or field names.
#
# Also note: You'll have to insert the output of 'django-admin.py sqlcustom [appname]'
# into your database.

from django.db import models


class FamilyTree(models.Model):
    family_tree_id = models.IntegerField(primary_key=True)
    family_tree_name = models.CharField(max_length=-1)
    family_tree_description = models.CharField(max_length=-1)
    class Meta:
        db_table = u'family_tree'

class FamilyTreeNode(models.Model):
    family_tree_node_id = models.IntegerField(primary_key=True)
    family_tree_node_name = models.CharField(max_length=-1)
    family_tree_node_abrev = models.CharField(max_length=-1)
    class Meta:
        db_table = u'family_tree_node'

class FamilyBuildMethod(models.Model):
    family_build_method_id = models.IntegerField(primary_key=True)
    family_build_method_name = models.CharField(max_length=-1)
    family_build_method_desc = models.CharField(max_length=-1)
    class Meta:
        db_table = u'family_build_method'

class FamilyBuild(models.Model):
    family_build_id = models.IntegerField(primary_key=True)
    famaily_build_name = models.CharField(max_length=-1)
    family_build_desc = models.CharField(max_length=-1)
    family_build_method = models.ForeignKey(FamilyBuildMethod)
    family_build_timestamp = models.DateTimeField()
    class Meta:
        db_table = u'family_build'

class Sequence(models.Model):
    sequence_id = models.IntegerField(primary_key=True)
    seguid = models.CharField(unique=True, max_length=-1)
    alphabet = models.CharField(max_length=-1)
    length = models.IntegerField()
    sequence = models.CharField(max_length=-1)
    class Meta:
        db_table = u'sequence'


class FamilyTreeInstance(models.Model):
    node_id = models.IntegerField(primary_key=True)
    parent_node = models.ForeignKey('self')
    family_tree_node = models.ForeignKey(FamilyTreeNode)
    rank = models.IntegerField()
    family_tree = models.ForeignKey(FamilyTree)
    class Meta:
        db_table = u'family_tree_instance'

class FamilyMember(models.Model):
    family_member_id = models.IntegerField(primary_key=True)
    family_build = models.ForeignKey(FamilyBuild)
    node = models.ForeignKey(FamilyTreeInstance)
    sequence = models.ForeignKey(Sequence)
    class Meta:
        db_table = u'family_member'

class Genome(models.Model):
    genome_id = models.IntegerField(primary_key=True)
    genome_name = models.CharField(max_length=-1)
    class Meta:
        db_table = u'genome'

class Species(models.Model):
    species_id = models.IntegerField(primary_key=True)
    genus = models.CharField(max_length=-1)
    species = models.CharField(max_length=-1)
    sub_species = models.CharField(max_length=-1)
    common_name = models.CharField(max_length=-1)
    class Meta:
        db_table = u'species'


class Db(models.Model):
    db_id = models.IntegerField(primary_key=True)
    genome = models.ForeignKey(Genome)
    db_name = models.CharField(max_length=-1)
    db_type = models.CharField(max_length=-1)
    class Meta:
        db_table = u'db'

class SequenceInformation(models.Model):
    sequence_information_id = models.IntegerField(primary_key=True)
    sequence = models.ForeignKey(Sequence)
    accession = models.CharField(max_length=-1)
    db = models.ForeignKey(Db)
    species = models.ForeignKey(Species)
    display = models.CharField(max_length=-1)
    description = models.CharField(max_length=-1)
    gene_name = models.CharField(max_length=-1)
    fullname = models.CharField(max_length=-1)
    alt_fullname = models.CharField(max_length=-1)
    symbols = models.CharField(max_length=-1)
    class Meta:
        db_table = u'sequence_information'

class SourceFile(models.Model):
    file_name = models.CharField(max_length=-1, primary_key=True)
    path = models.CharField(max_length=-1)
    sequence_file_desc = models.CharField(max_length=-1)
    file_type = models.CharField(max_length=-1)
    class Meta:
        db_table = u'source_file'

class SequenceFeature(models.Model):
    sequence_feature_id = models.IntegerField(primary_key=True)
    sequence = models.ForeignKey(Sequence)
    rank = models.IntegerField()
    primary_tag = models.CharField(max_length=-1)
    class Meta:
        db_table = u'sequence_feature'

class SequenceSourceFile(models.Model):
    sequence_source_file_id = models.IntegerField(unique=True)
    sequence = models.ForeignKey(Sequence)
    file_name = models.ForeignKey(SourceFile, db_column='file_name')
    class Meta:
        db_table = u'sequence_source_file'

class SequenceTag(models.Model):
    sequence_tag_id = models.IntegerField(primary_key=True)
    sequence_feature = models.ForeignKey(SequenceFeature)
    name = models.CharField(max_length=-1)
    value = models.CharField(max_length=-1)
    class Meta:
        db_table = u'sequence_tag'

class SequenceLocation(models.Model):
    sequence_location_id = models.IntegerField(primary_key=True)
    sequence_feature = models.ForeignKey(SequenceFeature)
    rank = models.IntegerField()
    start_pos = models.IntegerField()
    end_pos = models.IntegerField()
    strand = models.IntegerField()
    class Meta:
        db_table = u'sequence_location'


class Dblink(models.Model):
    dblink_id = models.IntegerField(primary_key=True)
    section = models.CharField(max_length=-1)
    sequence = models.ForeignKey(Sequence)
    db = models.CharField(max_length=-1)
    href = models.CharField(max_length=-1)
    class Meta:
        db_table = u'dblink'


