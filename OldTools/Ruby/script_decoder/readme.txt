スクリプトデコーダ

ダウンロードしたaiちゅーんおよびドラマのスクリプトファイルを
デコードするプログラムです。

<必要なもの>
- Ruby
  http://www.ruby-lang.org/ja/ 参照。あまり古いと動かないはず。
  手元ではCygwin版Rubyで動作確認してます。
- ダウンロードしてきたスクリプトファイル
  ai_sp@ce\user\ユーザ番号\1\dl\drama\以下にあるai*.txtファイルがそれです。

<使い方>
1. スクリプトファイルを入手します

2. デコーダを起動します。具体的にはコマンドラインから

ruby decoder.rb スクリプトファイル [...]

のように起動します。スクリプトファイルは複数指定できます。

デコードしたドラマスクリプトやaiちゅーんスクリプトは、
元のファイルの".txt"サフィックスを"_drama.txt", "_chara.txt", "_tune.txt"に
それぞれ置き換えたものとなります。

例: もともとのスクリプトファイルが"foo\bar.txt"だった場合、
ドラマスクリプトは"foo\bar_drama.txt"に、
キャラクタ定義ファイルは"foo\bar_chara.txt"にそれぞれ生成されます。
aiちゅーんだった場合は"foo\bar_tune.txt"です。

<その他>
デフォルトでは出力する文字コードはEUC-JP、改行コードはLFです。
Windows用(文字コードはCP932、改行コードはCR+LF)に変更したい場合は、
デコーダスクリプトの先頭付近を書き換えてください。

変更前
	NKF_OPT = '-W16L --unix'	# UNIX用
	#NKF_OPT = '-W16L --windows'	# Windows用

変更後
	#NKF_OPT = '-W16L --unix'	# UNIX用
	NKF_OPT = '-W16L --windows'	# Windows用

また、ai sp@ce利用規約およびai sp@ce著作物利用規約の範囲内で使用してください。
