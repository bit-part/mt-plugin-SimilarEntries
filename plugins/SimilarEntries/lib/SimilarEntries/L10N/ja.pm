package SimilarEntries::L10N::ja;

use strict;
use base 'SimilarEntries::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
    # config.yaml
    'bit part LLC' => 'bit part 合同会社',
    'description of SimilarEntries' => 'SimilarEntriesの説明',

    # config_template.tmpl
    'JSON URL to relate' => '関連付け用JSONのURL',
    'Enter the JSON URL to associate entries.' => '記事を関連性を割り出すための JSON の URL を入力します',
    'JSON URL to output HTML' => '出力用JSONのURL',
    'Enter the JSON URL to output HTML.' => '最終的に出力する内容が記載された JSON の URL を入力します',
    'Enter JavaScript to output by the tag of MTSimilarEntriesShow.' => 'MTSimilarEntriesShow タグで出力する JavaScript を入力します',

    # ContextHandlers.pm
    'The fields modifier is required.' => 'fieldsモディファイアは必須です。'
);

1;
