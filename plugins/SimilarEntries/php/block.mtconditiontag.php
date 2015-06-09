<?php
function smarty_block_mtiftag($args, $content, &$ctx, &$repeat) {
    if(!isset($content)) {
        // set condition here...
        $condition = false;
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat, $condition);
    }
    else {
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat);
    }
}
?>
