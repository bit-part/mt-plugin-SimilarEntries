package SimilarEntries::ContextHandlers;

use strict;
use warnings;

use MT::Entry;
use MT::Tag;

sub plugin {
    return MT->component('SimilarEntries');
}

sub get_setting {
    my ($key, $blog_id, $parent_id) = @_;
    my $plugin = plugin();
    my $value = $plugin->get_config_value($key, 'blog:' . $blog_id);
    unless ($value) {
        if ($parent_id) {
            $value = $plugin->get_config_value($key, 'blog:' . $parent_id);
        }
    }
    unless ($value) {
        $value = $plugin->get_config_value($key, 'system');
    }
    return $value;
}

#----- Tags
sub hdlr_similar_entries_template_json {
    my ($ctx, $args, $cond) = @_;

    my $blog_id = $ctx->stash('blog_id');
    my @include_blogs = $args->{include_blogs} ? split(/,/, $args->{include_blogs}) : ($blog_id);

    my $term = {
        blog_id => \@include_blogs,
        status  => MT::Entry::RELEASE(),
    };
    my $arg = {
        sort => 'authored_on',
        direction => 'descend',
    };
    my $iter = MT->model('entry')->load_iter($term, $arg);

    my $json = {};
    while (my $entry = $iter->()) {
        local $ctx->{__stash}{entry} = $entry;
        local $ctx->{__stash}{blog} = MT->model('blog')->load($entry->blog_id);
        local $ctx->{current_timestamp} = $entry->authored_on;
        local $ctx->{modification_timestamp} = $entry->modified_on;

        my $tokens = $ctx->stash('tokens');
        my $builder = $ctx->stash('builder');
        defined(my $value = $builder->build($ctx, $tokens, $cond))
            or return $ctx->error($builder->errstr);
        my $key = 'e' . $entry->id;
        $value =~ s/^\s+|\s+$//g;
        $json->{$key} = $value;
    }
    require JSON;
    return JSON::to_json($json);
}

sub hdlr_similar_entries_relate_json {
    my ($ctx, $args) = @_;

    my $plugin = plugin();
    unless ($args->{fields}) {
        return $ctx->error($plugin->translate('The fields modifier is required.'));
    }

    my $blog_id = $ctx->stash('blog_id');
    my $json = {
        blog => $blog_id,
    };

    my @include_blogs = $args->{include_blogs} ? split(/,/, $args->{include_blogs}) : ($blog_id);

    my $term = {
        blog_id => \@include_blogs,
        status  => MT::Entry::RELEASE(),
    };
    my @entries = MT->model('entry')->load($term);

    foreach my $key (split(/,/, $args->{fields})) {
        $json->{$key} = {};
    }

    foreach my $entry (@entries) {
        my $entry_id = $entry->id;
        # tags
        if (defined $json->{tags}) {
            my @tags = $entry->get_tags;
            if (@tags) {
                foreach my $tag (@tags) {
                    $tag = _sanitize_key($tag);
                    _entry_id_in_field($json, 'tags', $tag, $entry_id);
                }
            }
        }
        # category
        if (defined $json->{category}) {
            my $categories = $entry->categories;
            if ($categories) {
                foreach my $category (@$categories) {
                    my $label = $category->label;
                    $label = _sanitize_key($label);
                    _entry_id_in_field($json, 'category', $label, $entry_id);
                }
            }
        }
        # other fields
        my $separator = $args->{separator} ? $args->{separator} : ',';
        foreach my $field (keys %$json) {
            next if ($field eq 'blog' || $field eq 'tags' || $field eq 'category');
            next unless ($entry->has_column($field));
            my $value = $entry->$field;
            next unless $value;
            my @values =split(/$separator/, $value);
            foreach my $key (@values) {
                $key = _sanitize_key($key);
                _entry_id_in_field($json, $field, $key, $entry_id);
            }
        }
    }

    require JSON;
    return JSON::to_json($json);
}

sub hdlr_similar_entries_show {
    my ($ctx, $args) = @_;

    my $plugin = plugin();

    my $entry = $ctx->stash('entry')
        or return $ctx->_no_entry_error();
    my $entry_id = $entry->id;

    my $fields = $args->{fields}
        or return $ctx->error($plugin->translate('The [_1] modifier is required.', 'fields'));

    my $fields_json = {};
    foreach (split(/,/, $fields)) {
        if ($_ eq 'tags') {
            my @tags = $entry->get_tags;
            if (@tags) {
                $fields_json->{tags} = {};
                foreach my $tag (@tags) {
                    $tag = _sanitize_key($tag);
                    _entry_id_in_field($fields_json, 'tags', $tag, $entry_id);
                }
            }
        }
        elsif ($_ eq 'category') {
            my $categories = $entry->categories;
            if (@$categories) {
                $fields_json->{category} = {};
                foreach my $category (@$categories) {
                    my $label = $category->label;
                    $label = _sanitize_key($label);
                    _entry_id_in_field($fields_json, 'category', $label, $entry_id);
                }
            }
        }
        else {
            my $field = $_;
            my $separator = $args->{separator} ? $args->{separator} : ',';
            next unless ($entry->has_column($field));
            my $value = $entry->$field;
            next unless $value;
            $fields_json->{$field} = {};
            my @values =split(/$separator/, $value);
            foreach my $key (@values) {
                $key = _sanitize_key($key);
                _entry_id_in_field($fields_json, $field, $key, $entry_id);
            }
        }
    }
    require JSON;
    my $fields_json_str = JSON::to_json($fields_json);

    my $blog_id = $ctx->stash('blog_id');
    my $parent_id = $ctx->stash('blog')->parent_id;

    if (my $conf_js = get_setting('similar_entries_show_js', $blog_id, $parent_id)) {
        return $conf_js;
    }
    my $conf_relate = get_setting('related_json_url', $blog_id, $parent_id);
    my $conf_show = get_setting('related_show_json_url', $blog_id, $parent_id);

    my $limit = $args->{limit} ? $args->{limit} : 10;
    my $out = <<"_EOD_";
<script>
</script>
_EOD_
    return $out;
}

sub _entry_id_in_field {
    my ($json, $key1, $key2, $entry_id) = @_;
    if (defined $json->{$key1}->{$key2}) {
        push(@{$json->{$key1}->{$key2}}, $entry_id);
    }
    else {
        $json->{$key1}->{$key2} = [$entry_id];
    }
}

sub _sanitize_key {
    my ($key) = @_;
    $key =~ s/\s//g;
    return $key;
}

1;
