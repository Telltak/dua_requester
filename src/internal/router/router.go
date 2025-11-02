package router

import (
	"context"
	"log/slog"

	"github.com/aws/aws-lambda-go/events"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

type Handler func(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error)

type Router struct {
	Logger *slog.Logger
	routes map[string]map[string]Handler
}

func New(logger *slog.Logger) *Router {
	return &Router{
		Logger: logger,
		routes: make(map[string]map[string]Handler),
	}
}

func (r *Router) Handle(method, path string, handler Handler) {
	if r.routes[path] == nil {
		r.routes[path] = make(map[string]Handler)
	}
	r.routes[path][method] = handler
}

func (r *Router) Route(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	span := trace.SpanFromContext(ctx)
	span.SetAttributes(
		attribute.String("http.request.method", req.RequestContext.HTTP.Method),
		attribute.String("http.route", req.RawPath),
	)

	if pathHandlers, ok := r.routes[req.RawPath]; ok {
		if handler, ok := pathHandlers[req.RequestContext.HTTP.Method]; ok {
			resp, err := handler(ctx, req)
			span.SetAttributes(attribute.Int("http.response.status_code", resp.StatusCode))
			return resp, err
		}
	}

	resp := events.APIGatewayV2HTTPResponse{StatusCode: 404}
	span.SetAttributes(attribute.Int("http.response.status_code", resp.StatusCode))
	return resp, nil
}
