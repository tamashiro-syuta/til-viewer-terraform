import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { Octokit } from "@octokit/rest";
import dayjs from "dayjs";
import { v4 as uuidv4 } from "uuid";

// DynamoDBの設定
const dynamoDbClient = new DynamoDBClient({ region: "us-east-1" });

// GitHubの設定
const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN!,
});

// DynamoDBのテーブル名
const TABLE_NAME = "file-commits-table";

export const handler = async (_event: any) => {
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
