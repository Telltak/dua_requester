package main

import (
	"context"

	"dua_requester/internal/db"
	"dua_requester/internal/handlers"
	"dua_requester/internal/otel"
	"dua_requester/internal/router"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"go.opentelemetry.io/contrib/instrumentation/github.com/aws/aws-lambda-go/otellambda"
)

var r *router.Router

func handler(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	return r.Route(ctx, req)
}

func main() {
	ctx := context.Background()

	otelCfg, err := otel.New(ctx)
	if err != nil {
		panic(err)
	}

	dbClient, err := db.New(ctx)
	if err != nil {
		panic(err)
	}

	app := &handlers.App{
		Logger:   otelCfg.Logger,
		DBClient: dbClient,
	}

	r = router.New(otelCfg.Logger)
	r.Handle("POST", "/api/dua", app.PostDua)
	r.Handle("GET", "/api/duas", app.GetDuas)
	r.Handle("GET", "/api/duas/count", app.GetDuaCount)
	r.Handle("PATCH", "/api/dua/{ulid}", app.PatchDua)

	lambda.Start(otellambda.InstrumentHandler(handler))
}
