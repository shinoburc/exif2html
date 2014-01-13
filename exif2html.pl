#!/usr/bin/perl -w
#
# $Id: exif2html.pl 150 2009-10-12 12:50:48Z dot $
#

use strict;

use File::Basename;
use File::Copy;
use File::Copy::Recursive qw(rcopy);

use Image::ExifTool;
use Data::Dumper;

my $title = basename($ARGV[0]);

my %output_settings = (
        'base'          => 'exif2html'
       ,'index'         => 'index.html'
       ,'detail'        => 'gallery'
       ,'gallery'       => 'gallery/exif2html'
       ,'gallery_xml'   => 'gallery/exif2html/gallery.xml'
       ,'photo'         => 'gallery/exif2html/images'
       ,'thumbnail'     => 'gallery/exif2html/thumbnails'
       ,'imago_scripts' => 'imago/scripts'
       ,'imago_styles'  => 'imago/styles'
);

&init;
&main($ARGV[0]);

sub main($){
    my $dir = shift;

    my $exif = new Image::ExifTool;
    my %photo_files = ();

    opendir(DIR,$dir) or die "cannot read directory $dir : $!\n";
    while(my $file = readdir(DIR)){
        next if $file eq "." or $file eq ".." or $file !~ /.jpg$/i;
        $exif->ExtractInfo($dir . "/" . $file);

        my $html_filename = basename($file) . '.html';
        my $thumbnail_filename = '/' . basename($file);

        #my $html = $output_settings{'base'} . '/' . $output_settings{'detail'} . '/' . $html_filename;
        my $html = $output_settings{'base'} . '/' . $output_settings{'photo'} . '/' . $html_filename;
        my $thumbnail = $output_settings{'base'} . '/' . $output_settings{'thumbnail'} . $thumbnail_filename;

        copy($dir . '/' . $file, $output_settings{'base'} . '/' . $output_settings{'photo'} . '/' . $file);
        &output_html($exif,$html,basename($output_settings{'thumbnail'}) . $thumbnail_filename);
        &output_thumbnail($exif,$thumbnail);

        my %photo_info = (
            'basename'              => basename($file, '.jpg')
           ,'date'                  => $exif->GetValue('DateTimeOriginal')
           ,'html_filename'         => $html_filename
           ,'thumbnail_filename'    => $thumbnail_filename
           ,'point'                 => &get_point($exif)
           ,'a' => 'b'
        );
        $photo_files{$exif->GetValue('DateTimeOriginal') . $file} = \%photo_info;
    }
    closedir(DIR);

    &gen_index_xml(\%photo_files);
    &gen_index_html;
}

sub gen_index_xml(%){
    my $photo_files = shift;

    open OUT,'>' . $output_settings{'base'} . '/' . $output_settings{'gallery_xml'} or die "cannot open $output_settings{'gallery_xml'} : $!\n";

    print OUT '<?xml version="1.0" encoding="UTF-8"?>' . "\n\n";
    print OUT '<simpleviewerGallery maxImageHeight="80" maxImageWidth="60" textColor="0xFFFFFF" frameColor="0xffffff" frameWidth="20" stagePadding="40" thumbnailColumns="3" thumbnailRows="5" navPosition="left" title="' . $title . '" enableRightClickOpen="true" backgroundImagePath="" thumbPath="thumbnails/" imagePath="images/" >' . "\n";
    foreach my $key (sort keys %{$photo_files}){
        print OUT '<image>';
        print OUT '<filename>' . $photo_files->{$key}->{'thumbnail_filename'} . '</filename>';

        print OUT '<caption>';
        #print OUT '&lt;a href="' . $output_settings{'detail'} . '/' . $photo_files->{$key}->{'html_filename'} . '" target="_blank"&gt;';
        print OUT $photo_files->{$key}->{'date'};
        #print OUT '&lt;/a&gt;';
        print OUT '</caption>';

        print OUT '</image>';
    }
    print OUT '</simpleviewerGallery>';
    close OUT;
}

sub gen_index_html($){
    open OUT,'>' . $output_settings{'base'} . '/' . $output_settings{'index'} or die "cannot open $output_settings{'index'} : $!\n";

    print OUT <<"END_OF_INDEX_HTML";
<?xml version="1.0" encoding="ISO-8859-1" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />
<title>Imago - Testpage</title>
<link rel="stylesheet" href="styles/imago.css" type="text/css" />
<script src="scripts/mootools.v1.11.js" type="text/javascript"></script>
<script src="scripts/imago.js" type="text/javascript"></script>
</head>
<body>

<div style="">
        <div id="imagogallery" class="imagogallery" >
        this.loader = new GalleryLoader('gallery.xml', 'gallery', "exif2html");
        </div>
</div>
        <div id="map">
        <iframe id="map_iframe" src="" width="100%" height="800" scrolling="auto" />
        </div>
</body>
</html>
END_OF_INDEX_HTML
    close OUT;
}

sub init(){
    # initialize directories
    mkdir($output_settings{'base'}) if !-d $output_settings{'base'};
    mkdir($output_settings{'base'} . '/' . $output_settings{'detail'}) if !-d $output_settings{'base'} . '/' . $output_settings{'detail'};
    mkdir($output_settings{'base'} . '/' . $output_settings{'gallery'}) if !-d $output_settings{'base'} . '/' . $output_settings{'gallery'};
    mkdir($output_settings{'base'} . '/' . $output_settings{'photo'}) if !-d $output_settings{'base'} . '/' . $output_settings{'photo'};
    mkdir($output_settings{'base'} . '/' . $output_settings{'thumbnail'}) if !-d $output_settings{'base'} . '/' . $output_settings{'thumbnail'};
    rcopy($output_settings{'imago_scripts'}, $output_settings{'base'} . '/scripts');
    rcopy($output_settings{'imago_styles'}, $output_settings{'base'} . '/styles');
}

sub get_point($){
    my $exif = shift;
    my $latitude  = $exif->GetValue('GPSLatitude');
    my $longitude = $exif->GetValue('GPSLongitude');

    return '0,0' if !defined($latitude) or !defined($longitude);

    $latitude =~ /(.+?) deg (.+?)' (.+?)"/;
    my $latitude_value = $1 + ($2/60) + ($3/(60*60));

    $longitude =~ /(.+?) deg (.+?)' (.+?)"/;
    my $longitude_value = $1 + ($2/60) + ($3/(60*60));
    return $latitude_value . ',' . $longitude_value;

    # http://maps.google.co.jp/maps?q=37.771008,+-122.41175+(TEXT)&iwloc=A&hl=ja
}

sub output_thumbnail($$){
    my $exif = shift;
    my $file = shift;
    my $thumbnail = $exif->GetValue('ThumbnailImage');
    return unless $thumbnail;

    open my $thumbnail_file, '>', $file or die $!;
    binmode $$thumbnail_file;
    print $thumbnail_file $$thumbnail;
    close $thumbnail_file;
}

sub output_html($$){
    my $exif = shift;
    my $file = shift;
    my $icon = shift;

    my $point = &get_point($exif);
    open OUT, '>', $file or die $!;

    print OUT<< "END_OF_HTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>Google マップ</title>
    <script src="http://maps.google.co.jp/maps?hl=ja&amp;file=api&amp;v=2&amp;key=ABQIAAAApv75wD_ns8N8-D_papWoWRQ_iREKWWQT2Wr4UTRda5Oz4I3ZuBQJS6TyGqhYHgixQ814JoWA_AZKmg"
            type="text/javascript"></script>
    <script type="text/javascript">

    function initialize() {
      if (GBrowserIsCompatible()) {
        var map = new GMap2(document.getElementById("map_canvas"));
        var mp = new GLatLng($point);
        var icon = new GIcon();
        //icon.image = "$icon";
        map.setCenter(mp, 14);
        map.addControl(new GLargeMapControl());
        map.addControl(new GMapTypeControl());
        //var marker = new GMarker(mp, {icon: icon});
        var marker = new GMarker(mp);
        map.addOverlay(marker);

        var street_view = new GStreetviewPanorama(document.getElementById("street_view_canvas"));
        street_view.setLocationAndPOV(mp);
      }
    }

    </script>
  </head>

  <body onload="initialize()" onunload="GUnload()">
    <div id="map_canvas" style="width: 400px; height: 300px; float:left;"></div>
    <div id="street_view_canvas" style="width: 400px; height: 300px; float:left;"></div>
  </body>
</html>
END_OF_HTML

    close OUT;
}
