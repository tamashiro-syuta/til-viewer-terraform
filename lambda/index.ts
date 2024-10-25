import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from "@aws-sdk/client-secrets-manager";
import { APIGatewayEvent, ProxyResult } from "aws-lambda";
import { Octokit } from "@octokit/rest";
import dayjs from "dayjs";
import { v4 as uuidv4 } from "uuid";

const REGION = "ap-northeast-1";
const dynamoDbClient = new DynamoDBClient({ region: REGION });
const TABLE_NAME = "file-commits-table";

export const handler = async (event: APIGatewayEvent): Promise<ProxyResult> => {
  const client = new SecretsManagerClient({ region: REGION });
  const response = await client.send(
    new GetSecretValueCommand({
      SecretId: "GITHUB_TOKEN",
    })
  );

  const secret = JSON.parse(response.SecretString!);
  const octokit = new Octokit({ auth: secret.GITHUB_TOKEN });
  try {
    // 前日の開始・終了時間を取得（UTC）
    const yesterday = dayjs().subtract(1, "day");
    const since = yesterday.startOf("day").toISOString();
    const until = yesterday.endOf("day").toISOString();

    // GitHub APIを使って、前日のコミットを取得
    const response = await octokit.rest.repos.listCommits({
      owner: "tamashiro-syuta",
      repo: "TIL",
      since,
      until,
    });

    const commitCount = response.data.length;

    // DynamoDBにレコードを保存
    const putParams = {
      TableName: TABLE_NAME,
      Item: {
        date: { S: yesterday.format("YYYYMMDD") },
        path: { S: uuidv4() }, // NOTE: pathはもう必要ないからランダムな値を入れている
        commitCount: { N: commitCount.toString() },
      },
    };

    await dynamoDbClient.send(new PutItemCommand(putParams));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Commit count successfully saved to DynamoDB",
        commit_count: commitCount,
      }),
    };
  } catch (error) {
    console.error("Error:", error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Failed to fetch commit count or save to DynamoDB",
        error: error,
      }),
    };
  }
};
