package SimilarEntries::Plugin;

use strict;
use warnings;

sub plugin {
    return MT->component('SimilarEntries');
}

sub _log {
    my ($msg) = @_;
    return unless defined($msg);
    my $prefix = sprintf "%s:%s:%s: %s", caller();
    $msg = $prefix . $msg if $prefix;
    use MT::Log;
    my $log = MT::Log->new;
    $log->message($msg) ;
    $log->save or die $log->errstr;
    return;
}

sub get_setting {
    my $plugin = plugin();
    my ($value, $blog_id) = @_;
    my %plugin_param;

    $plugin->load_config(\%plugin_param, 'blog:'.$blog_id);
    my $value = $plugin_param{$value};
    unless ($value) {
        $plugin->load_config(\%plugin_param, 'system');
        $value = $plugin_param{$value};
    }
    $value;
}


#----- Transformer
sub hdlr_edit_entry_source {
    my ($cb, $app, $tmpl_ref) = @_;

    1;
}

sub hdlr_edit_entry_output {
    my ($cb, $app, $tmpl_str_ref, $param, $tmpl) = @_;

    1;
}

sub hdlr_edit_entry_param {
    my ($cb, $app, $param, $tmpl) = @_;

    1;
}

#----- Hook
sub hdlr_cms_pre_save_entry {
    my ($cb, $app, $obj, $original) = @_;

    1;
}

sub hdlr_cms_post_save_entry {
    my ($cb, $app, $obj) = @_;

    1;
}

sub hdlr_cb_build_page {
    my ($cb, %args) = @_;
    my $content_ref = $args{Content};

    1;
}

1;
