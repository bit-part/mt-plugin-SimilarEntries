package SimilarEntries::ContextHandlers;

use strict;
use warnings;

use MT::Entry;
use MT::Tag;

sub plugin {
    return MT->component('SimilarEntries');
}

use MT::Log;
use Data::Dumper;
use File::Basename;
sub doLog {
    my ($msg, $code) = @_;
    return unless defined($msg);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $year += 1900;
    $mon += 1;
    # my $now = "$year年$mon月$mday日($youbi[$wday]) $hour時$min分$sec秒\n";
    my $now = "$year/$mon/$mday $hour:$min:$sec";
    my $log = MT::Log->new;
    $log->message("[$now] $msg");
    $log->metadata($code);
    $log->save or die $log->errstr;
}

# doLog(basename(FILE).':'.LINE, Dumper($can_access_blogs));

sub get_setting {
    my ($key, $blog_id, $parent_id) = @_;

    my $plugin = plugin();
    my $value = $plugin->get_config_value($key, 'blog:' . $blog_id);
doLog('$value: '.$value);
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
sub hdlr_similar_entries {
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

sub hdlr_similar_entries_create_json {
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

    # require MT::App::DataAPI;
    # require MT::DataAPI::Endpoint::Entry;
    # my $entries = MT::DataAPI::Resource::Type::ObjectList->new();
    # my $entries = MT::App::DataAPI->new;
    # doLog(Dumper($entries));

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
                    # if (defined $json->{tags}->{$tag}) {
                    #     push(@{$json->{tags}->{$tag}}, $entry_id);
                    # }
                    # else {
                    #     $json->{tags}->{$tag} = [$entry_id];
                    # }
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
                    # if (defined $json->{category}->{$label}) {
                    #     push(@{$json->{category}->{$label}}, $entry_id);
                    # }
                    # else {
                    #     $json->{category}->{$label} = [$entry_id];
                    # }
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
                # if (defined $json->{$field}->{$key}) {
                #     push(@{$json->{$field}->{$key}}, $entry_id);
                # }
                # else {
                #     $json->{$field}->{$key} = [$entry_id];
                # }
            }
        }
    }

    my $count = @entries;
    doLog($count);
    doLog(Dumper($entries[10]));


    # if ($include_blogs) {
    #     foreach ( split(/,/, $include_blogs) ) {
    #         my $blog = MT->model('blog')->load($_);
    #         if ($blog) {
    #             push (@blog_ids);
    #         }
    #     }
    # }
    # doLog(Dumper($ctx->{__stash}->{blog}->id));
    # return $include_blogs;

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
        or return $ctx->error($plugin->translate('The fields modifier is required.'));

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
var similarEntries = similarEntries || {};
similarEntries.data = $fields_json_str;
similarEntries.get = function(url, success){
    var req = new XMLHttpRequest();
    req.arguments = Array.prototype.slice.call(arguments, 2);
    req.onload = function(){
        success(req, JSON.parse(req.response));
    };
    req.onerror = function(){
        console.error(req.statusText);
    };
    req.open("get", url, true);
    req.send(null);
}
similarEntries.objectSort = function(array, key, order, type){
    order = (order === 'ascend') ? -1 : 1;
    array.sort(function(obj1, obj2){
        var v1 = obj1[key];
        var v2 = obj2[key];
        if (type === 'numeric') {
            v1 = v1 - 0;
            v2 = v2 - 0;
        }
        else if (type === 'string') {
            v1 = '' + v1;
            v2 = '' + v2;
        }
        if (v1 < v2) {
            return 1 * order;
        }
        if (v1 > v2) {
            return -1 * order;
        }
        return 0;
    });
}
similarEntries.get('$conf_relate', function(xhr, json){
    var similarIDs = [];
    var similarRank = {};
    var similarRankSort = [];
    for (var key1 in similarEntries.data) {
        for (var key2 in similarEntries['data'][key1]) {
            if (json[key1][key2]) {
                Array.prototype.push.apply(similarIDs, json[key1][key2]);
            }
        }
    }
    for (var i = 0, l = similarIDs.length; i < l; i++) {
        var id = 'e' + similarIDs[i];
        if (similarRank[id]) {
            similarRank[id]++;
        }
        else {
            similarRank[id] = 1;
        }
    }
    for (var key in similarRank) {
        var obj = {};
        obj['id'] = key;
        obj['count'] = similarRank[key];
        similarRankSort.push(obj);
    }
    similarEntries.objectSort(similarRankSort, 'count', 'descend');
    var html = '';
    var max = similarRankSort.length;
    similarEntries.get('$conf_show', function(xhr, json){
        for (var i = 0; i < $limit; i++) {
            if (i == max) {
                break;
            }
            html += json[similarRankSort[i]['id']];
        }
        document.getElementById('similar-entries').innerHTML = html;
    });
});
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

# sub hdlr_if {
#     my ($ctx, $args, $cond) = @_;

#     1;
# }

#----- Global filter
# sub similar_entries {
#     my ($text, $arg, $ctx) = @_;
#     $arg or return $text;

#     $text;
# }

1;
