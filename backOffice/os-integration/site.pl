#replace this file with your own config
#see sample-site.pl
if(exists $ENV{'DISPLAY'} and defined $ENV{'DISPLAY'})
{
	warn "You haven't configured L'ane yet!\nSee http://wiki.l-ane.net/wiki/Install_RPM\n";
	use Tk;
	my $top = MainWindow->new;
	$top->title("L'ane: ERROR");
	$top->Button(
	    '-text' => "You haven't configured L'ane yet!\nSee http://wiki.l-ane.net/wiki/Install_RPM\n\nClose",
	    '-command' => sub {exit 1;},
	)->pack;
	Tk::MainLoop;
}
die "You haven't configured L'ane yet!\nSee http://wiki.l-ane.net/wiki/Install_RPM\n";
