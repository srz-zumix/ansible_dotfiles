# Bash script 実行中の上書き動作についての検証

## これはなにか

[スーパーコンピュータシステムのファイル消失のお詫び | お知らせ | 京都大学情報環境機構](https://www.iimc.kyoto-u.ac.jp/ja/whatsnew/information/detail/211228056999.html)

データ消失の原因が実行中の bash script を上書きしたことにより、意図しない挙動を起こしてしまったとのこと。

この挙動はスクリプトをよく書いてる人なら知ってることだと思いますが、
ふと ansible でコピーしたときって大丈夫なのか？
という疑問がわいたので試してみました。

## 結果

![result](https://user-images.githubusercontent.com/1439172/206874423-6986bc9f-fda5-4005-a872-b331bb2bd343.png)

ansible の copy module はこの問題は起きませんでした。安心して使えますね。
処理的には python の os.rename でファイル更新しています。
[atomic_move](https://github.com/ansible/ansible/blob/devel/lib/ansible/module_utils/basic.py#L1653)
ファイル更新する処理は大抵 automic_move を使ってそうなので copy module 以外もおそらく大丈夫なはず。

もしなんらかスクリプトを実行してその中でコピーする場合は `mv -f` 使ったほうが良さそう。
