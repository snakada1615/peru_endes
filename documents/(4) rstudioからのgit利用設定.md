<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Rstudioからgithubへのコミットができない問題への対応

以下の手順で、RStudioのGitタブからCommit/Pushできない問題を解消しました。

------------------------------------------------------------------------

## 1. SSH認証の設定

1.  SSH鍵ペアを作成（`ssh-keygen` または RStudio GUI）
2.  公開鍵を GitHub の **Settings \> SSH and GPG keys** に登録
3.  `ssh -T git@github.com` で認証を確認
    -   「Hi snakada1615! …」のメッセージで成功

## 2. コマンドラインでのコミット動作確認

-   ターミナル上で `commit.gpgsign=false` を設定

``` bash
git config --global commit.gpgsign false
```

-   コマンドラインからは正常に Commit/Push が実行可能

## 3. RStudio Gitタブでのエラー発生

-   RStudioのGitタブで Commit 時に以下エラー

```         
error: gpg failed to sign the data
fatal: failed to write commit object
```

-   Git設定上は `commit.gpgsign=false` になっているにも関わらず、RStudioが `--gpg-sign` オプションを付与していた

## 4. 問題の原因と解決

-   **原因**: RStudioの「Sign git commit」オプションが有効で、GPG署名を強制していた
-   **解決策**: RStudio の **Tools \> Global Options \> Git/SVN** で「Sign git commit」のチェックをオフ

------------------------------------------------------------------------

以上により、RStudioのGitタブからSSH認証を使った通常のCommit/Pushが問題なく動作するようになりました。
