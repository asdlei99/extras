#Last Updated: 2005.02.16 (xris)
#
#  export::ffmpeg::ASF
#  Maintained by Gavin Hurlbut <gjhurlbu@gmail.com>
#

package export::ffmpeg::ASF;
    use base 'export::ffmpeg';

# Load the myth and nuv utilities, and make sure we're connected to the database
    use nuv_export::shared_utils;
    use nuv_export::cli;
    use nuv_export::ui;
    use mythtv::db;
    use mythtv::recordings;

# Load the following extra parameters from the commandline
    add_arg('a_bitrate|a=i',    'Audio bitrate');
    add_arg('v_bitrate|v=i',    'Video bitrate');

    sub new {
        my $class = shift;
        my $self  = {
                     'cli'             => qr/\basf\b/i,
                     'name'            => 'Export to ASF',
                     'enabled'         => 1,
                     'errors'          => [],
                    # ffmpeg-related settings
                     'noise_reduction' => 1,
                     'deinterlace'     => 1,
                     'crop'            => 1,
                    # ASF-specific settings
                     'a_bitrate'       => 64,
                     'v_bitrate'       => 256,
                     'width'           => 320,
                     'height'          => 240,
                    };
        bless($self, $class);

    # Initialize and check for ffmpeg
        $self->init_ffmpeg();
    # Can we even encode asf?
        if (!$self->can_encode('msmpeg4')) {
            push @{$self->{'errors'}}, "Your ffmpeg installation doesn't support encoding to msmpeg4.";
        }
        if (!$self->can_encode('mp3')) {
            push @{$self->{'errors'}}, "Your ffmpeg installation doesn't support encoding to mp3 audio.";
        }
    # Any errors?  disable this function
        $self->{'enabled'} = 0 if ($self->{'errors'} && @{$self->{'errors'}} > 0);
    # Return
        return $self;
    }

    sub gather_settings {
        my $self = shift;
    # Load the parent module's settings
        $self->SUPER::gather_settings();

    # Audio Bitrate
        if (arg('a_bitrate')) {
            $self->{'a_bitrate'} = arg('a_bitrate');
            die "Audio bitrate must be > 0\n" unless (arg('a_bitrate') > 0);
        }
        else {
            $self->{'a_bitrate'} = query_text('Audio bitrate?',
                                              'int',
                                              $self->{'a_bitrate'});
        }
    # Ask the user what video bitrate he/she wants
        if (arg('v_bitrate')) {
            die "Video bitrate must be > 0\n" unless (arg('v_bitrate') > 0);
            $self->{'v_bitrate'} = arg('v_bitrate');
        }
        elsif ($self->{'multipass'} || !$self->{'vbr'}) {
            # make sure we have v_bitrate on the commandline
            $self->{'v_bitrate'} = query_text('Video bitrate?',
                                              'int',
                                              $self->{'v_bitrate'});
        }
    # Query the resolution
        $self->query_resolution();
    }

    sub export {
        my $self    = shift;
        my $episode = shift;
    # Load nuv info
        load_finfo($episode);
    # Build the ffmpeg string
        $self->{'ffmpeg_xtra'} = " -b "  . $self->{'v_bitrate'}
                               . " -vcodec msmpeg4"
                               . " -ab " . $self->{'a_bitrate'}
                               . " -acodec mp3"
                               . " -s "  . $self->{'width'} . "x" . $self->{'height'}
                               . " -f asf";
    # Execute the parent method
        $self->SUPER::export($episode, ".asf");
    }

1;  #return true

# vim:ts=4:sw=4:ai:et:si:sts=4