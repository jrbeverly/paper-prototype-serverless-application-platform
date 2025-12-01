using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Amazon.Runtime;

var tableName = Environment.GetEnvironmentVariable("TABLE_NAME") ?? "dev-items";

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddAWSLambdaHosting(LambdaEventSource.RestApi);
builder.Services.AddSingleton<IAmazonDynamoDB>(_ =>
{
    var endpoint = Environment.GetEnvironmentVariable("DYNAMODB_ENDPOINT");
    if (!string.IsNullOrEmpty(endpoint))
    {
        var config = new AmazonDynamoDBConfig { ServiceURL = endpoint };
        return new AmazonDynamoDBClient(new BasicAWSCredentials("local", "local"), config);
    }
    return new AmazonDynamoDBClient();
});

var app = builder.Build();

app.MapGet("/api/items", async (IAmazonDynamoDB db) =>
{
    var result = await db.ScanAsync(new ScanRequest { TableName = tableName });
    return result.Items.Select(i => new
    {
        id = i.TryGetValue("pk", out var pk) ? pk.S : null,
        name = i.TryGetValue("name", out var n) ? n.S : null,
    });
});

app.MapPost("/api/items", async (CreateItemRequest body, IAmazonDynamoDB db) =>
{
    var id = Guid.NewGuid().ToString();
    await db.PutItemAsync(new PutItemRequest
    {
        TableName = tableName,
        Item = new Dictionary<string, AttributeValue>
        {
            ["pk"] = new() { S = id },
            ["name"] = new() { S = body.Name },
        },
    });
    return Results.Created($"/api/items/{id}", new { id, body.Name });
});

app.Run();

record CreateItemRequest(string Name);
