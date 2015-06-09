<?php
function smarty_block_mtcontainertag($args, $content, &$ctx, &$repeat) {
    $localvars = array('_items', '_items_counter', 'item');
    if(!isset($content)) {
        $ctx->localize($localvars);
        // load items here...
        $items = array();
        $ctx->stash('_items', $items);
        $counter = 0;
    }
    else {
        $items = $ctx->stash('_items');
        $counter = $ctx->stash('_items_counter');
    }
    if($counter < count($items)) {
        $item = $items[$counter];
        $ctx->stash('item', $item);
        $ctx->stash('_items_counter', $counter + 1);
        $repeat = true;
    }
    else {
        $ctx->restore($localvars);
        $repeat = false;
    }
    return $content;
}
?>
