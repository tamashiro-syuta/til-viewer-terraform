import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from "@aws-sdk/client-secrets-manager";
import { ProxyResult } from "aws-lambda";
import dayjs from "dayjs";
import { v4 as uuidv4 } from "uuid";

type Argument = {
  dateString: string; // NOTE: 'YYYY-MM-DD' 形式の文字列
  secretId: string;
};

const REGION = "ap-northeast-1";
const dynamoDbClient = new DynamoDBClient({ region: REGION });
const TABLE_NAME = "file-commits-table";

export const handler = async ({
  dateString,
  secretId,
}: Argument): Promise<ProxyResult> => {
  const client = new SecretsManagerClient({ region: REGION });
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: secretId })
  );

  const secret = JSON.parse(response.SecretString!);
  try {
    // NOTE: 前日の開始・終了時間を取得（UTC）
    const dateInstance = dayjs(dateString);
    const since = dateInstance.startOf("day").toISOString();
    const until = dateInstance.endOf("day").toISOString();

    // NOTE: GitHub APIを直接呼び出して、前日のコミットを取得
    const url = `https://api.github.com/repos/tamashiro-syuta/TIL/commits?since=${encodeURIComponent(
      since
    )}&until=${encodeURIComponent(until)}`;

    const githubResponse = await fetch(url, {
      method: "GET",
      headers: {
        Authorization: `token ${secret.GITHUB_TOKEN}`,
        Accept: "application/vnd.github.v3+json",
      },
    });

    if (!githubResponse.ok) {
      throw new Error(
        `GitHub API error: ${githubResponse.status} ${githubResponse.statusText}`
      );
    }

    const data = await githubResponse.json();

    console.log("Data:", data);

    const commitCount = (data as any).length;

    // NOTE: DynamoDBにレコードを保存
    const putParams = {
      TableName: TABLE_NAME,
      Item: {
        date: { S: dateInstance.format("YYYYMMDD") },
        path: { S: uuidv4() }, // NOTE: pathはもう必要ないからランダムな値を入れている
        commitCount: { N: commitCount },
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
