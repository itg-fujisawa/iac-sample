# 環境昇格（旧 09 stg/prod の手順）

1. PR 作成 → `iac-preview.yaml` が dev の Preview を作成し、証跡バケットへ保存
2. レビュー承認 → main マージ → dev の Deploy
3. stg：同じコミットで Preview → 差分レビュー → Deploy → 受入試験（性能・WAF 誤検知・復元）
4. prod：Cloud Build の「承認が必要」トリガーで Deploy（`scripts/im.sh` はローカルからの prod apply を拒否）
5. アプリ：stg で試験済みの **同一 digest** を `ci/cloudbuild/app-promote.yaml`（`_SOURCE_IMAGE`=stg の digest）で prod へ昇格（再ビルドしない）

記録：変更ID、コミット、Preview 名、Revision、Build ID、承認者、結果。
