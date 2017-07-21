SimilarEntries - Movable Type プラグイン
=================

## 概要

SimilarEntries は、記事の任意のフィールドの値をキーにして、その記事に関連する記事をリストアップする Movable Type プラグインです。

## 特徴

- 関連付けの判定に利用するフィールドを自由に選択可能（複数フィールド可）
- 静的に書き出した JSON を JavaScript で動的に読み込み関連付けを判定
- JSON ファイルはファンクションタグ１つで簡単に書き出し

## 仕組み

SimilarEntries プラグインは、下記の仕組みで関連記事の判定・表示を行います。

1. 関連記事判定用の JSON を作成
1. 関連記事表示用の JSON を作成
1. 関連記事を判定する JavaScript ファイルを読み込み
1. 判定用の JSON を Ajax で読み込み関連記事の ID を取得
1. 表示用の JSON を Ajax で読み込み、上で取得した ID に該当する記事の HTML を出力

## 動作環境

* Movable Type 6 以降で確認済み
* Google Chrome、Firefox、IE9以上

## インストール

1. [releases](https://github.com/bit-part/mt-plugin-SimilarEntries/releases)よりアーカイブファイルをダウンロードします。
1. ダウンロードしたファイルを展開します。
1. 展開したファイルをMovable Typeのプラグインディレクトリにアップロードします。

インストールしたディレクトリ構成は下記のようになります。

    $MT_HOME
    ├── plugins
    │   └── SimilarEntries
    └── mt-static
        └── plugins
            └── SimilarEntries

## 使い方

### 関連記事判定用の JSON ファイルを作成<br> - MTSimilarEntriesRelateJSON ファンクションタグ

関連記事を判定するための JSON ファイルをインデックステンプレートで書き出します。JSON は、MTSimilarEntriesRelateJSON タグにいくつかのモディファイアを指定するだけで書き出せます。

    <mt:SimilarEntriesRelateJSON
        include_blogs="7"
        fields="tags,keywords,field.text01,category">

MTSimilarEntriesRelateJSON タグで利用できるモディファイアは下記の通りです。

#### fields（必須）

判定の対象とするフィールドのベースネームを指定します。複数指定するときはカンマで区切ります。

カテゴリを指定する場合は「category」と指定します。

カスタムフィールドを指定する場合は「field.text01」のように「field.カスタムフィールドのベースネーム」という形式で指定します。

    fields="tags,keywords,field.text01,category"

#### include_blogs

判定対象とするブログの ID を指定します。複数指定するときはカンマで区切ります。

    include_blogs="1,2,3"

#### include_categories

特定のカテゴリに属する記事を判定対象としたい場合に、判定対象に含むカテゴリの ID を指定します。複数指定するときはカンマで区切ります。

    include_categories="1,2,3"

### 関連記事を表示するフォーマットを指定<br> - MTSimilarEntriesTemplateJSON ブロックタグ

関連記事を表示するための HTML を値に持つ JSON ファイルをインデックステンプレートで書き出します。MTSimilarEntriesTemplateJSON ブロックタグの中に表示させたい形のテンプレートを書けば、自動で JSON が作成されます。

    <mt:SimilarEntriesTemplateJSON include_blogs="7">
    <li><a href="<mt:EntryPermalink>"><mt:EntryTitle></a>（<mt:BlogName>）［<mt:EntryPrimaryCategory><mt:CategoryLabel></mt:EntryPrimaryCategory>］</li>
    </mt:SimilarEntriesTemplateJSON>

このサンプルコードで出力される JSON は下記のようになります。

    {
        e718: "<li><a href="/SimilarEntries/archives/000718.html">すべてのページで同じ「最近のブログ記事一覧」を表示するカスタマイズ</a>（SimilarEntries）［MT Customize］</li>",
        e725: "<li><a href="/SimilarEntries/archives/000725.html">一定時間で自動的に消える New マークを付ける JavaScript の jQuery 版</a>（SimilarEntries）［JavaScript］</li>",
        （省略）
    }

MTSimilarEntriesTemplateJSON タグで利用できるモディファイアは下記の通りです。

#### include_blogs

判定対象とするブログの ID を指定します。複数指定するときはカンマで区切ります。

### 関連記事を表示する - SimilarEntriesShow ファンクションタグ

#### fields（必須）

前述の MTSimilarEntriesRelateJSON タグと同様です。

#### relation_url（必須）

MTSimilarEntriesRelateJSON タグで書き出した関連記事判定用の JSON ファイルの URL を指定します。

#### template_url（必須）

MTSimilarEntriesTemplateJSON タグで書き出した関連記事表示用の JSON ファイルの URL を指定します。

#### script_url

SimilarEntries.js ファイルの URL を指定します。
このモディファイアを指定しない場合は、mt-static/plugins/SimilarEntries/js 内にあるファイルを読み込むようになります。

#### limit

関連記事の表示件数を指定します。
何も指定しない場合は 10 がセットされます。


#### target_selector

関連記事を表示する DOM の CSS セレクターを指定します。
何も指定しない場合は `#similar-entries` がセットされます。

#### include_current

このモディファイアに 1 を指定すると関連記事のリストに現在の記事を含めて表示します。何も指定しない場合は 0 がセットされます。

#### priority

各フィールドの優先度を指定します。下記のようにフィールドの後に「:1」のようにして優先度を設定します。

    priority="tags:10,keywords:3,category:1"

この場合、キーワードが2つ一致(6)したとしても、タグが1つでも一致(10)すれば、タグが一致した方が優先度が高くなります。

#### first

関連記事をループして表示する前に一度だけ挿入する HTML 文字列を指定します。

例えば、関連記事を li 要素で表示する場合は、このモディファイアに `<ul>` と指定すれば良いでしょう。

#### last

関連記事をループして表示した後に一度だけ挿入する HTML 文字列を指定します。

例えば、関連記事を li 要素で表示する場合は、このモディファイアに `</ul>` と指定すれば良いでしょう。

#### each_function

関連記事を出力するループで毎回実行される関数を指定します。

    function(i, text, odd, even, current){
        if (odd) {
            text = text.replace(/<li/, '<li class="odd"');
        }
        else if (even) {
            text = text.replace(/<li/, '<li class="even"');
        }
        if (i % 3 == 0) {
            text += '</ul><ul>'
        }
        return text;
    }

この関数には、`i`、`text`、`odd`、`even`、`current` の5つの引数が渡されます。

- i : ループの回数が渡されます。1 から始まります。
- text : ループ中の関連記事のテキスト（SimilarEntriesTemplateJSON タグで設定した内容）が渡されます。このテキストを書き換え、 `return text;` すれば表示を細かく制御出来ます。
- odd : 奇数回目のループの時に `true` が渡されます。
- even : 偶数回目のループの時に `true` が渡されます。
- current : ループの関連記事が現在表示されているページの記事である時に `true` が渡されます。

#### 例

    <mt:SetVarBlock name="first"><ul></mt:SetVarBlock>
    <mt:SetVarBlock name="last"></ul></mt:SetVarBlock>
    <mt:SetVarBlock name="each_function">
    function(i, text, odd, even){
        if (odd) {
            text = text.replace(/<li/, '<li class="odd"');
        }
        else if (even) {
            text = text.replace(/<li/, '<li class="even"');
        }
        if (i % 3 == 0) {
            text += '</ul><ul>'
        }
        return text;
    }
    </mt:SetVarBlock>

    <mt:SimilarEntriesShow
        fields="tags,keywords,field.text01,category"
        relation_url="http://your-host/SimilarEntries/relation.json"
        template_url="http://your-host/SimilarEntries/template.json"
        target_selector="#similar-entries"
        limit="5"
        first="$first"
        last="$last">
    </div>

## 料金

「無料プラン」と「商用プラン」の２つを用意し、Movable Type 本体のライセンスを基準に区分けしています。

### 無料プラン

個人無償ライセンス、開発者ライセンスの Movable Type と組み合わせる場合はこちらになります。

No asking, take your own risk.

### 商用プラン

商用ライセンスの Movable Type と組み合わせる場合は以下の内容になります。

* 10,000円（＋税） / 1インストール（サイト）

ライセンスの購入は下記の「bit part shop」からお願いいたします。

bit part shop
[http://bitpart.thebase.in/](http://bitpart.thebase.in/)

---

MT::Lover::[bitpart](http://bit-part.net/)
