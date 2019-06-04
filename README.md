# アプリケーションリポジトリ

# 使い方

1. ECRのリポジトリを作成
aws ecr create-repository --repository-name sample

2. deploy.shを実行

# datadog APIKeyの登録
aws ssm put-parameter --name "/sample-default/datadog/api_key" --type String --value <APIKEY>
