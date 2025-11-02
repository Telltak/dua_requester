package db

import (
	"context"
	"os"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

type Client struct {
	svc       *dynamodb.Client
	tableName string
}

func New(ctx context.Context) (*Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, err
	}

	return &Client{
		svc:       dynamodb.NewFromConfig(cfg),
		tableName: os.Getenv("TABLE_NAME"),
	}, nil
}

func (c *Client) PutItem(ctx context.Context, item map[string]interface{}) error {
	return nil
}

func (c *Client) GetItem(ctx context.Context, key map[string]interface{}) (map[string]interface{}, error) {
	return nil, nil
}
