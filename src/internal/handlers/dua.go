package handlers

import (
	"context"
	"log/slog"

	"dua_requester/internal/db"

	"github.com/aws/aws-lambda-go/events"
)

type App struct {
	Logger   *slog.Logger
	DBClient *db.Client
}

func (a *App) PostDua(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	a.Logger.InfoContext(ctx, "creating dua")
	return events.APIGatewayV2HTTPResponse{StatusCode: 201}, nil
}

func (a *App) GetDuas(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	a.Logger.InfoContext(ctx, "listing duas")
	return events.APIGatewayV2HTTPResponse{StatusCode: 200}, nil
}

func (a *App) GetDuaCount(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	a.Logger.InfoContext(ctx, "getting dua count")
	return events.APIGatewayV2HTTPResponse{StatusCode: 200, Body: "It's alive!"}, nil
}

func (a *App) PatchDua(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	a.Logger.InfoContext(ctx, "updating dua")
	return events.APIGatewayV2HTTPResponse{StatusCode: 200}, nil
}
