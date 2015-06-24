var similarEntries = similarEntries || {};

similarEntries.config = {};
similarEntries.get = function(url, success){
    if (!url) {
        return;
    }
    var req = new XMLHttpRequest();
    req.arguments = Array.prototype.slice.call(arguments, 2);
    req.onload = function(){
        success(req, JSON.parse(req.response));
    };
    req.onerror = function(){
        console.error(req.statusText);
    };
    req.open('get', url, true);
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
similarEntries.show = function(config){
    similarEntries.get(config.relationURL, function(xhr, json){
        var similarIDs = [];
        var similarRank = {};
        var similarRankSort = [];
        for (var key1 in config.data) {
            for (var key2 in similarEntries['config']['data'][key1]) {
                if (json[key1][key2]) {
                    if (config.includeCurrent == 0 && json[key1][key2] == config.currentId) {
                        continue;
                    }
                    else {
                        Array.prototype.push.apply(similarIDs, json[key1][key2]);
                    }
                }
            }
        }
        for (var i = 0, l = similarIDs.length; i < l; i++) {
            if (config.includeCurrent == 0 && config.currentId == similarIDs[i]) {
                continue;
            }
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
        similarEntries.get(config.templateURL, function(xhr, json){
            for (var i = 0; i < config.limit; i++) {
                if (i == max) {
                    break;
                }
                if (i == 0 && config.first) {
                    html += config.first;
                }
                if (typeof config.each === 'function') {
                    var counter = i + 1;
                    var odd = (counter % 2 == 1);
                    var even = (counter % 2 == 0);
                    var current = (similarRankSort[i]['id'] == ('e' + config.currentId));
                    html += config.each(counter, json[similarRankSort[i]['id']], odd, even, current);
                }
                else {
                    html += json[similarRankSort[i]['id']];
                }
                if (config.last) {
                    if (i == (config.limit - 1) || i == (max - 1)) {
                        html += config.last;
                    }
                }
            }
            var target = document.querySelectorAll(config.targetSelector);
            for (var i = 0, l = target.length; i < l; i++) {
                target[i].innerHTML = html;
            }
        });
    });
};
