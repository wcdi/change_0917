# change_0917
パッケージマネージャーがダウンロードに使うミラーサーバーを[mirror.hashy0917.net](https://mirror.hashy0917.net)に変更するスクリプトです。

## 使い方
(curl: ほぼ全て)
```bash
curl https://wcdi.adw39.org/change_0917/run.sh | sh
```
(wget: openwrtなど)
```bash
wget -O - https://wcdi.adw39.org/change_0917/run.sh | sh
```


- root権限で動かす必要があります。
- httpsを使う方が無難です。
- 念の為、パッケージリスト更新時(`apt update`等)にurlが正しく設定されているか確認してください。
- **作者は当スクリプトを使って起きたトラブルによる責任は負いません。**
