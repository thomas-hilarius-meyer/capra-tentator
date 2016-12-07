#!/usr/bin/perl

# tentator - Multiple-Choice-Tests erstellen - Projektbeginn: 13.11.2016
#                                                    Version: 13.11.2016
#
# Wunschliste	- Test als ausführbares Programm
#				- Auswertung in einem file sammeln, lesbar für mentor:
#					.txt als Rückmeldung für die Schüler
#					.pdf (mit Latex) zum Ausdrucken
#					.csv für Notenimport
#				- Verstecken der Auswertungsdatei (clickbar)
#				- ganzes Erstellungsprogramm in einer Datei (here-documents)

use strict;
use utf8;
use open ':encoding(utf8)';
use Data::Dumper;
$Data::Dumper::Purity = 1;
use Tk;
use Tk::DialogBox;
use Tk::Pane;    # nötig seit Einbau der scrollbars

#use Tk::ComboBox;
use Tk::BrowseEntry;
use Encode qw(decode encode);

use Net::FTP;
use File::Copy;

$SIG {"QUIT"} = \&ende;
$SIG {"INT"} = \&ende;
$SIG {"STOP"} = \&ende;


my $vorname;
my $nachname;

use vars qw($thema 
			@fragen
			@antwortalternativen
			@loesungen
			@fragetyp
			$anzeigemodus
			$fragen_randomisieren
			$antworten_randomisieren
			$auswertungsdatei_verstecken
			$filename);

my $filename_prg;

$anzeigemodus = "karten";
$fragen_randomisieren = "ja";
$antworten_randomisieren = "ja";
$auswertungsdatei_verstecken = "nein";


my @antwort;

our $main = MainWindow->new( -title => "capra:tentator - Multiple-Choice-Tests erstellen" );

$main->protocol('WM_DELETE_WINDOW',\&ende);

my $ms = $main -> Scrolled(
        "Frame",
        -scrollbars => "se",
        -height     => "400",
        -width      => "600"
    )->pack( -fill => "both", -expand => "1" );

my $fontsize_std = 12;
$main ->fontCreate( 'std',  -size => $fontsize_std );

$ms->Label(
    -text   => "Datei: ",
    -width  => "20",
    -anchor => "e",
    -font   => 'std'
    )->grid(
    $ms -> Label(
        -textvariable => \$filename,
        -width        => "40",
        -anchor       => "w",
        -font         => 'std'
    )
    );

$ms->Label(
    -text   => "Ausführbare PRG-Datei: ",
    -width  => "20",
    -anchor => "e",
    -font   => 'std'
    )->grid(
    $ms -> Label(
        -textvariable => \$filename_prg,
        -width        => "40",
        -anchor       => "w",
        -font         => 'std'
    )
    );

$ms->Label(
    -text   => "Thema: ",
    -width  => "20",
    -anchor => "e",
    -font   => 'std'
    )->grid(
    $ms -> Entry(
        -textvariable => \$thema,
        -width        => "40",
        -font         => 'std'
    )
    );



$ms -> Button (
		    -text => "Datei laden",
            -font    => 'std',
            -command => \&datei_laden,
		) -> grid("-");


$ms -> Button (
		    -text => "Fragen bearbeiten",
            -font    => 'std',
            -command => \&fragen_bearbeiten,
		) -> grid("-");
		
$ms -> Button (
		    -text => "Datei speichern",
            -font    => 'std',
            -command => \&datei_speichern,
		) -> grid("-");

$ms -> Label ( -text => "Optionen für das Test-Programm:",
			-font    => 'std') -> grid ("-");

$ms -> Radiobutton (
			-text    => "Listenansicht",
			-value   => "liste",
			-variable => \$anzeigemodus
		) -> grid ("-");
$ms -> Radiobutton (
			-text    => "Karteikartenansicht",
			-value   => "karten",
			-variable => \$anzeigemodus
		) -> grid ("-");

$ms -> Checkbutton (
			-text     => "Auswertungsdatei verstecken",
			-onvalue  => "ja",
			-offvalue => "nein",
			-variable => \$auswertungsdatei_verstecken
		) -> grid ("-");

			
$ms -> Checkbutton (
			-text    => "Aufgabenreihenfolge randomisieren",
			-onvalue => "ja",
			-offvalue => "nein",
			-variable => \$fragen_randomisieren
		) -> grid ("-");

$ms -> Checkbutton (
			-text    => "Antwortenreihenfolge randomisieren",
			-onvalue => "ja",
			-offvalue => "nein",
			-variable => \$antworten_randomisieren
		) -> grid ("-");


$ms -> Button (
		    -text => "Testfile (Programm) bauen!",
            -font    => 'std',
            -command => \&testfile_bauen,
		) -> grid("-");
		
$ms -> Button (
		    -text => "Ende",
            -font    => 'std',
            -command => \&ende,
		) -> grid("-");

my $fr;

MainLoop;

sub datei_laden {
	undef $/;  # ????????????????????????????????????????????????

	$filename = $main->getOpenFile(
			-title      => "Klasse laden",
			-filetypes  => [ [ "capra:tentator-Dateien", [".tent"] ], [ "alle Dateien", ["*"] ] ],
            -initialdir => "."
		);
		
	open DATEI, "$filename" or die "File not found.";
	eval <DATEI> or die "Fehler bei Auswertung!";
	close DATEI;
};

sub fragen_bearbeiten {
	$fr = $main->DialogBox(
        -title   => "Testaufgaben bearbeiten",
        -buttons => ["OK"]
    );
    $fr -> Label( -text =>
            "Testaufgaben:"
    ) -> pack();

	my $frs = $fr -> Scrolled(
        "Frame",
        -scrollbars => "se",
        -height     => "400",
        -width      => "700"
    )->pack( -fill => "both", -expand => "1" );

    
	
	for ( my $i = 0; $i < @fragen; $i++ ) {
		$fragetyp[$i] = "mc4";
		$frs -> Entry (
		    -textvariable => \$fragen[$i],
            -font    => 'std',
            -width   => '70',
		) -> grid("-");
		for ( my $j = 0; $j < 4; $j++ ) {
			$frs -> Entry(
                -textvariable     => \$antwortalternativen[$i][$j],
                -width   => '70',
            ) -> grid(
            $frs -> Radiobutton(
                -text     => "richtig?",
                -value    => $j,
                -variable => \$loesungen[$i]
            )
            );

		}
	}
	$frs -> Button (
		    -text => "Neue Frage",
            -font    => 'std',
            -command => \&neue_frage
		) -> grid();

	$fr->Show();


	};
	
sub neue_frage {
	push (@fragen, " ");
	$fr -> destroy;
	&fragen_bearbeiten;
}

sub datei_speichern {
    my $db = $main->DialogBox(
        -title   => "Testaufgaben speichern",
        -buttons => ["OK", "Cancel"]
    );
    $db->Label( -text =>
            "Dateiname mit der Endung .tent versehen! \n Entweder volle Pfadangabe oder nur Dateiname im aktuellen Verzeichnis möglich. \n Dateiname:"
    )->pack();
	$db->Entry( -textvariable => \$filename, -width => 50 )->pack();
	my $speichern = $db->Show();
	
	if ($speichern eq "OK") {
		open DATEI, ">$filename";
		print DATEI Data::Dumper->Dump( [ $filename_prg], ['*filename_prg'] );
		print DATEI Data::Dumper->Dump( [ $thema], ['*thema'] );
		
		print DATEI Data::Dumper->Dump( [ $anzeigemodus], ['*anzeigemodus'] );
	    print DATEI Data::Dumper->Dump( [ $fragen_randomisieren], ['*fragen_randomisieren'] );
	    print DATEI Data::Dumper->Dump( [ $antworten_randomisieren], ['*antworten_randomisieren'] );
		print DATEI Data::Dumper->Dump( [ $auswertungsdatei_verstecken], ['*$auswertungsdatei_verstecken'] );
		
		print DATEI Data::Dumper->Dump( [ \@fragen ],     ['*fragen'] );
		print DATEI Data::Dumper->Dump( [ \@antwortalternativen ],      ['*antwortalternativen'] );
		print DATEI Data::Dumper->Dump( [ \@loesungen ],     ['*loesungen'] );
		print DATEI Data::Dumper->Dump( [ \@fragetyp ],      ['*fragetyp'] );
		close DATEI;
		print "File $filename gespeichert.\n";
	}
};

sub testfile_bauen {   
    my $db = $main->DialogBox(
        -title   => "Testaufgaben als auführbares Programm fertigstellen",
        -buttons => ["OK", "Cancel"]
    );
    $db->Label( -text =>
            "Dateiname wird automatisch mit der Endung .pl versehen! \n Entweder volle Pfadangabe oder nur Dateiname im aktuellen Verzeichnis möglich. \n Dateiname:"
    )->pack();
	$db->Entry( -textvariable => \$filename_prg, -width => 50 )->pack();
	my $speichern = $db->Show();

		open DATEI, ">$filename_prg" . "pl";
		
		open PROLOG, "<tentator_lib_prolog";
		while (my $line = <PROLOG>) {
			print DATEI $line;
		}	
		close PROLOG;

		print DATEI Data::Dumper->Dump( [ $filename_prg], ['*filename_prg'] );
		print DATEI Data::Dumper->Dump( [ $thema], ['*thema'] );

	    print DATEI Data::Dumper->Dump( [ $anzeigemodus], ['*anzeigemodus'] );
	    print DATEI Data::Dumper->Dump( [ $fragen_randomisieren], ['*fragen_randomisieren'] );
	    print DATEI Data::Dumper->Dump( [ $antworten_randomisieren], ['*antworten_randomisieren'] );
		print DATEI Data::Dumper->Dump( [ $auswertungsdatei_verstecken], ['*$auswertungsdatei_verstecken'] );

		print DATEI Data::Dumper->Dump( [ \@fragen ],     ['*fragen'] );
		print DATEI Data::Dumper->Dump( [ \@antwortalternativen ],      ['*antwortalternativen'] );
		print DATEI Data::Dumper->Dump( [ \@loesungen ],     ['*loesungen'] );
		print DATEI Data::Dumper->Dump( [ \@fragetyp ],      ['*fragetyp'] );
		
		open EPILOG, "<tentator_lib_epilog";
		while (my $line = <EPILOG>) {
			print DATEI $line;
		}	
		close EPILOG;
		
		close DATEI;
	print "$filename_prg geschrieben";
};

sub ende {
	exit;
};


