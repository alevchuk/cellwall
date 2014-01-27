# vim:sw=4 ts=4
# $Id: default.pm 143 2005-07-15 20:52:50Z laurichj $

=head1 NAME

Cellwall::CGI::default

=head1 DESCRIPTION

Cellwall::CGI::default is the default theme for the Cellwall Navigator. This
is a simple theme that will be fairly easy to customize. However, there are
a handful of hacks to deal with different browsers.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::CGI::default;
use Error;
use base qw/Cellwall::CGI::threepane/;
use strict;

=head2 new

 Title   : new
 Usage   : $cgi = new Cellwall::CGI( ... )
 Function: Create a new default object
 Returns : a Cellwall::CGI::default object
 Args    :

 This wont be called directly, but rather as a result of the -style argument to
 Cellwall::CGI

=cut

sub new
{
	my $self = Cellwall::CGI::threepane::new(@_);

	# initialize the theme info
	# EDIT: change these values to alter the way the pages look
	# This theme makes heavy use of CSS, as all modern browsers
	# support CSS very well. This lets allmost all of the font and
	# color data be stored here.

	# Setup the body background and font
	$self->add_CSS(
		-name             => 'body',
		-background_color => '#FFFFFF',
		-color            => '#000000',
		-font_family      => 'avantgarde, sans-serif',
		-font_size        => '12pt',
	);
	
	# Setup the links
	$self->add_CSS(
		-name  => 'a',
		-color => '#0000FF',
		-text_decoration => 'none',
	);
	$self->add_CSS(
		-name  => 'a:hover',
		-background_color => '#AAAAAA',
		-text_decoration => 'underline',
	);

	# Setup the headers, otherwise some browsers get
	# it wrong
	$self->add_CSS(
		-name => 'h1, h2, h3, h4, h5, h6',
		-font_weight => 'bold',
	);
	$self->add_CSS( -name => 'h1', -font_size => '180%' );
	$self->add_CSS( -name => 'h2', -font_size => '150%' );
	$self->add_CSS( -name => 'h3', -font_size => '120%' );
	$self->add_CSS( -name => 'h4', -font_size => '120%' );
	
	# Used for sequence and other fixed-width displays
	$self->add_CSS(
		-name => 'pre',
		-font_family => 'FreeMono, monospace',
		-font_size => '10pt',
	);
	$self->add_CSS(
		-name => 'tt',
		-font_family => 'FreeMono, monospace',
		-font_size => '10pt',
	);

	# Setup the background colors for sequence highlighting
	$self->add_CSS( -name => 'tt.MODEL', -background_color => sprintf('rgb(%d, %d, %d)', map { hex } ( @{ $Cellwall::colors{ lightblue   } } ) ) );
	$self->add_CSS( -name => 'tt.EXON',  -background_color => sprintf('rgb(%d, %d, %d)', map { hex } ( @{ $Cellwall::colors{ cyan        } } ) ) );
	$self->add_CSS( -name => 'tt.CDS',   -background_color => sprintf('rgb(%d, %d, %d)', map { hex } ( @{ $Cellwall::colors{ orange      } } ) ) );
	$self->add_CSS( -name => 'tt.UTRS',  -background_color => sprintf('rgb(%d, %d, %d)', map { hex } ( @{ $Cellwall::colors{ lime        } } ) ) );
	$self->add_CSS( -name => 'tt.MISC',  -background_color => 'rgb(170, 170, 170)' );

	return $self;
}

sub display
{
	my($self) = @_;

	$self->mime("text/html; charset=UTF-8");
	print $self->headers();

	print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"' , "\n",
	      '    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' . "\n",
	      '<html xmlns="http://www.w3.org/1999/xhtml" lang="en"',
	      ' xml:lang="en">', "\n",
	      '<head><meta http-equiv="Cache-Control" content="no-cache"/>', "\n", 
		  '<meta http-equiv="Pragma" content="no-cache"/>', "\n", 
		  '<meta http-equiv="Expires" content="0"/>', "\n";

	print sprintf("<title>%s</title>\n", $self->get_Title()) if defined $self->get_Title();

	foreach my $meta ($self->get_Meta()) {
		print '<meta ', join(' ', map { sprintf('%s="%s"', $_, $meta->{$_}) } keys(%$meta)), "/>\n";
	}

	# TODO: Print Meta Data
	print "\n<style type='text/css'>\n";
	print 'table { width: 100%; background-color: #D3D3D3; vertical-align: top; text-align: center; text-indent: 0pt; }', "\n";
	print 'table { border: 0px; border-collapse: collapse; margin: 0px; }', "\n";
	print 'table.page { background-color: #FFFFFF; min-width: 1024px; position:absolute; left:0em; top:1em; }', "\n";
	print 'tr, td { vertical-align: top; text-align: left; }', "\n";
	print '.leftbar { width: 15%; }', "\n";
	print '.rightbar { width: 10%; }', "\n";
	print '.contents, .titlebar { width: 75%; }', "\n";
	print '.contents, .titlebar { text-align: center; }', "\n";
	print '.contents { margin-bottom: 2em; }', "\n";
	print 'form { width: 85%; }', "\n";
	print '.contents > *, .leftbar > *, .rightbar > * { margin-left: auto; margin-right: auto; }', "\n";
	print 'img { border-width: 0px; }', "\n";
	print '.container { width: 85%; margin-bottom: 1em; text-align: left; }', "\n";
	print 'form .container { width: 100%; }', "\n";
	print '.paragraph, .header { width: 100%; background-color: #D3D3D3; vertical-align: top; }', "\n";
	print '.title { background-color: #AAAAAA; text-indent: 0pt; }', "\n";
	print '.header { background-color: #AAAAAA; }', "\n";
	print '.bold { font-weight: bold; }', "\n";
	print '.menu { text-align: center; }', "\n";
	print '.menu > * { margin-left: auto; margin-right: auto; }', "\n";
	print 'td[align="right"] { text-align: right; }', "\n";

	foreach my $css ($self->get_CSS()) {
		print $css->{name}, " { ", join("; ", map { sprintf("%s: %s", $_, $css->{$_}) } grep { $_ ne "name" } keys(%$css)), "} \n";
	}
	print "</style>\n";
	

	print "</head>\n", '<body>', 
	      '<table class="page"><tr><td class="leftbar"></td><td class="titlebar">';


	# We use the image as the title.
	print '<a href="http://www.cepceb.ucr.edu/"><img alt="Cellwall Database" src="cwDatabase.gif"/></a>', "\n";
	print '<h3>', $self->sub_title(), '</h3>', "\n" if $self->sub_title();

	print '</td><td class="rightbar"></td></tr>', "\n",
	      '<tr><td class="rightbar">', "\n";

	# Print the Menus
	print $self->apply_templates($self->get_Left());

	print "</td>\n",
	      '<td class="contents">', "\n";

	# Print the main pane
	print $self->apply_templates($self->get_Contents());

	print '</td><td class="rightbar">', "\n";

	# print the right pane
	print $self->apply_templates($self->get_Right());

	print '</td></tr></table></body></html>';
}

sub apply_templates
{
	my($self, @args) = @_;
	my @data;

	while(defined(my $item = shift(@args))) {
		if(ref($item) eq 'ARRAY') {
			push(@data, $self->apply_templates(@{$item}));
		} elsif($item eq '-para') {
			push(@data, $self->apply_para(@{shift @args}));
			#	push(@data, '<br><br>');
		} elsif($item eq '-table') {
			push(@data, $self->apply_table(@{shift @args}));
			#push(@data, '<br><br>');
		} elsif($item eq '-menu') {
			push(@data, $self->apply_menu(@{shift @args}));
			#push(@data, '<br><br>');
		} elsif($item eq '-form') {
			push(@data, $self->apply_form(@{shift @args}));
#		} elsif($item eq '-font') {
#			push(@data, $self->apply_font(@{shift @args}));
		} elsif($item eq '-link') {
			push(@data, $self->apply_link(@{shift @args}));
		} elsif($item eq '-list') {
			push(@data, $self->apply_list(@{shift @args}));
		} elsif($item eq '-include') {
			push(@data, $self->apply_include(shift @args));
		} elsif($item eq '-input') {
			push(@data, $self->apply_input(shift @args));
		} elsif($item eq '-img') {
			push(@data, $self->apply_img(@{shift @args}));
		} elsif($item eq '-map') {
			push(@data, $self->apply_map(@{shift @args}));
		} elsif($item =~ /^-(\w+)$/o) {
			my $next = shift(@args);
			push(@data, "<$1>" . $self->apply_templates(ref($next) ? @$next : $next) . "</$1>");
		} else {
			push(@data, $item);
		}
	}

	return join("\n", @data);
}

sub apply_include
{
	my($self, $file) = @_;
	my $twig = new XML::Twig();

	$twig->parsefile($file);
	my @ret = $self->apply_include_parse($twig);
	return $self->apply_templates(@ret);
}

sub apply_include_parse
{
	my($self, $twig) = @_;
	my @ret;
	foreach my $child ($twig->children()) {
		my $gi = $child->gi();
		if($gi eq "export") {
			return $self->apply_include_parse($child);
		} elsif($gi eq "menu") {
			push(@ret, "-menu", [$self->apply_include_parse_menu($child)]);
		}
	}
	return @ret;
}

sub apply_include_parse_menu
{
	my($self, $menu) = @_;
	my @ret;

	push(@ret, $menu->{att}->{title});
	foreach my $child ($menu->children()) {
		my $gi = $child->gi();
		if($gi eq "link") {
			my $url = $child->{att}->{href};
			push(@ret, "-$gi", [$child->trimmed_text(), $url]);
		}
	}
	return @ret;
}

#sub apply_font
#{
#	my($self, @args) = @_;
#	my $text;
#	my %params;
#	
#	while(defined(my $item = shift @args)) {
#		if(my($tag) = ($item =~ /^-(\w+)$/go)) {
#			if($item =~ /size/o) {
#				$params{$tag} = shift @args;
#			} else {
#				$text .= $self->apply_templates($item);
#			}
#		} else {
#			$text .= $item;
#		}
#	}
#	
#	$text = join(" ", "<font", map { "$_=\"$params{$_}\"" } keys(%params)) . ">" . $text . "</font>";
#	return $text;
#}

sub apply_form
{
	my($self, @args) = @_;
	my $text = '';
	my $action;
	my $method = 'get';
	my $name;
	my $enctype;

	if($args[0] eq '-action') {
		(undef, $action) = splice(@args, 0, 2);
	}
	if($args[0] eq '-method') {
		(undef, $method) = splice(@args, 0, 2);
	}
	if($args[0] eq '-name') {
		(undef, $name) = splice(@args, 0, 2);
	}
	if($args[0] eq '-enctype') {
		(undef, $enctype) = splice(@args, 0, 2);
	}

	$text  = "<form action='$action' method='$method'";
	$text .= " name='$name'" if defined $name;
	$text .= " enctype='$enctype'" if defined $enctype;
	$text .= ">";
	$text .= $self->apply_templates(@args);
	$text .= "</form>";
	return $text;
}

sub apply_input
{
	my($self, @args) = @_;
	my $text;
	my %h;

	if(scalar(@args) == 1 and ref($args[0]) eq "ARRAY") {
		@args = @{$args[0]};
	}


	while(defined(my $item = shift @args)) {
		if($item eq '-type') {
			$h{type} = shift(@args);
		} elsif($item eq '-name') {
			$h{name} = shift(@args);
			$h{value} = $self->get_Request($h{name});
		} elsif($item eq '-height') {
			$h{height} = shift(@args);
		} elsif($item eq '-width') {
			$h{width} = shift(@args);
		} elsif($item eq '-value') {
			$h{value} = shift(@args);
		} elsif($item eq '-default') {
			$h{default} = shift(@args);
		} elsif($item eq "-order") {
			$h{order} = shift(@args);
		} elsif($item eq '-target') {
			$h{target} = shift(@args);
		}
	}
	
	if($h{type} eq 'dropdown') {
		$text = $self->apply_input_dropdown(%h);
	} elsif($h{type} eq 'text') {
		$text = $self->apply_input_text(%h);
	} elsif($h{type} eq 'password') {
		$text = $self->apply_input_password(%h);
	} elsif($h{type} eq 'textarea') {
		$text = $self->apply_input_textarea(%h);
	} elsif($h{type} eq 'submit') {
		$text = $self->apply_input_submit(%h);
	} elsif($h{type} eq 'button') {
		$text = $self->apply_input_button(%h);
	} elsif($h{type} eq 'checkbox') {
		$text = $self->apply_input_checkbox(%h);
	} elsif($h{type} eq 'radio') {
		$text = $self->apply_input_radio(%h);
	} elsif($h{type} eq 'hidden') {
		$text = $self->apply_input_hidden(%h);
	}
	
	return $text;
}

sub apply_input_dropdown
{
	my($self, %h) = @_;
	my $text = "<select name='$h{name}' size=1>";
	my $selected = $h{default} || '';
	$h{order} = 'value' unless $h{order};

	my @keys = keys(%{$h{value}});
	if($h{order} eq "key") {
		@keys = sort @keys;
	} elsif($h{order} eq "value.number") {
		@keys = sort { $h{value}->{$a} <=> $h{value}->{$b} } @keys;
	} else {
		@keys = sort { $h{value}->{$a} cmp $h{value}->{$b} } @keys;
	}
	
	foreach my $key ( @keys ) {
		my $value = $h{value}->{$key} || $key;
		if($selected eq $key) {
			$text .= "<option value='$key' selected>$value</option>";
		} else {
			$text .= "<option value='$key'>$value</option>";
		}
	}

	$text .= "</select>";
	return $text;
}

sub apply_input_text
{
	my($self, %h) = @_;
	my $width = $h{width} || '45';
	return "<input type='text' name='$h{name}' size='$width' value='$h{value}'>";
}

sub apply_input_password
{
	my($self, %h) = @_;
	my $width = $h{width} || '45';
	return "<input type='password' name='$h{name}' size='$width'>";
}

sub apply_input_textarea
{
	my($self, %h) = @_;
	my $height = $h{height} || 5;
	my $width = $h{width} || '45';
	return "<textarea name='$h{name}' cols='$width' rows='$height'>$h{value}</textarea>";
}

sub apply_input_submit
{
	my($self, %h) = @_;
	return "<input type='submit' name='$h{name}' value='$h{value}'>";
#	return sprintf("<a onClick='Javascript:action.value = \"%s\"; %s.submit();' style='cursor: hand;'>%s</a>", lc $h{value}, $h{target}, $h{value});
}

sub apply_input_checkbox
{
	my($self, %h) = @_;
	return "<input type='checkbox' name='$h{name}' value='$h{value}'>";
}

sub apply_input_radio
{
	my($self, %h) = @_;
	return "<input type='radio' name='$h{name}' value='$h{value}'>";
}

sub apply_input_hidden
{
	my($self, %h) = @_;
	return "<input type='hidden' name='$h{name}' value='$h{value}'>";
}

sub apply_input_button
{
	my($self, %h) = @_;
	return "<input type='button' name='$h{name}' value='$h{value}'>";
}

sub apply_para
{
	my($self, @args) = @_;
	my $p = '';
	my $title;
	my $text = '';

	if($args[0] eq '-title') {
		(undef, $title) = splice(@args, 0, 2);
	}

	$p = $self->apply_templates(@args);
	$title = $self->apply_templates($title) if defined $title;

	return join("\n", '<div class="container">', 
	            ( defined $title ? "<div class='header'>$title</div>" : () ),
				'<div class="paragraph">', $p, '</div>', '</div>' );
}

sub apply_table
{
	my($self, @args) = @_;
	my @format;
	my $bit;

	$bit = shift(@args);
	if($bit eq "-format") {
		$bit = shift(@args);

		foreach my $r (@$bit) {
			push(@format, $r);
		}
	}

	my $text = '<div class="container"><table>' . "\n";

	while(defined($bit = shift(@args))) {
		if($bit eq "-header") {
			$text .= '<tr class="header">';
		} elsif($bit eq "-row") {
			$text .= '<tr>';
		}

		$text .= "\n";

		$bit = shift(@args);

		for(my($i, $j) = (0,0); $i < scalar(@$bit); $i++, $j++) {
			my %h = @{$format[$j]};
			my $cell;

			if(ref($bit->[$i]) eq "ARRAY") {
				while(defined(my $item = shift(@{$bit->[$i]}))) {
					if($item =~ /^-colspan/o) {
						$h{$item} = shift @{$bit->[$i]};
						delete $h{'-width'};
						$j += $h{$item} - 1;
					} elsif($item =~ /^-class$/o) {
						$h{$item} = shift @{$bit->[$i]};
					} elsif($item =~ /^-align/o) {
						$h{$item} = shift @{$bit->[$i]};
					} elsif($item =~ /^-width/o) {
						$h{$item} = shift @{$bit->[$i]};
					} elsif($item =~ /^-/o) {
						$cell = $self->apply_templates($item, shift @{$bit->[$i]});
					} else {
						$cell = $self->apply_templates($item);
					}
				}
			} elsif($bit->[$i] =~ /^-/o) {
				$cell = $self->apply_templates($bit->[$i], $bit->[++$i]);
			} else {
				$cell = $self->apply_templates($bit->[$i]);
			}
			$text .= '<td ' . join(" ", map { substr($_,1) . "=\"$h{$_}\"" } keys(%h)) . '>' . "\n";
			$text .= defined($cell) ? $cell : '' . "\n";
			$text .= '</td>' . "\n";
		}

		$text .= '</tr>';
	}
	$text .= '</table></div>';
	return $text;
}

sub apply_menu
{
	my($self, @args) = @_;
	my $title = shift @args;
	my $text = "";

	while(defined(my $link = shift(@args))) {
		if($link eq "-link") {
			$text .= $self->apply_link(@{shift(@args)}) . "<br/>\n";
		}
	}

	return '<table class="container menu"><tr class="bold header"><td>' . $title . ':</td></tr><tr><td><b>' . $text . '</b></td></tr></table>';
}

sub apply_link
{
	my($self) = shift @_;

	# Check for a class tag
	if( $_[0] eq '-class' ) {
		$_[2] = $self->apply_templates($_[2]);
		return "<a class=\"$_[1]\" href=\"$_[3]\">$_[2]</a>";
	}
	$_[0] = $self->apply_templates($_[0]);
	return "<a href=\"$_[1]\">$_[0]</a>";
	
#	my($self, $title, $url) = @_;
#	$title = $self->apply_templates($title);
#	return "<a href=\"$url\">$title</a>";
}

sub apply_list
{
	my($self, @args) = @_;
	my @items;
	
	while(defined(my $bit = shift @args)) {
		if($bit =~ /^-/) {
			push(@items, $self->apply_templates($bit, shift @args));
		} else {
			push(@items, $bit);
		}
	}
	return "[ " . join("; ", @items) . " ]";
}

sub apply_img
{
	my($self, @args) = @_;
	my %attr;

	while(defined((my $bit = shift @args))) {
		$attr{$1} = shift @args if $bit =~ /^-(\w+)$/o;
	}

	return "<img src=\"$attr{src}\""
	       . ( defined($attr{map}) ? " usemap=\"#$attr{map}\"" : '' )
		   . '>';
}
	
sub apply_map
{
	my($self, @args) = @_;
	my %attr;
	my @data;

	while(defined(my $bit = shift @args)) {
		if($bit eq '-name') {
			$attr{name} = shift @args;
		} elsif($bit eq '-area') {
			push(@data, $self->apply_area(@{shift @args}));
		}
	}

	return "<map name='$attr{name}'>" . join("", @data) . '</map>';
}

sub apply_area
{
	my($self, @args) = @_;
	my %attr;

	while(defined((my $bit = shift @args))) {
		$attr{$1} = shift @args if $bit =~ /^-(\w+)$/o;
	}

	return "<area href='$attr{href}' shape='$attr{shape}' coords='" . join(',', @{$attr{coords}}) . "'>";
}

1;
