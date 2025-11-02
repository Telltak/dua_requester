package router

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"github.com/aws/aws-lambda-go/events"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"
)

func setupTest() context.Context {
	tp := trace.NewTracerProvider(trace.WithSpanProcessor(tracetest.NewSpanRecorder()))
	otel.SetTracerProvider(tp)
	tracer := tp.Tracer("test")
	ctx, _ := tracer.Start(context.Background(), "test-span")
	return ctx
}

func TestRouter_Route(t *testing.T) {
	ctx := setupTest()
	called := false
	handler := func(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
		called = true
		return events.APIGatewayV2HTTPResponse{StatusCode: 200}, nil
	}

	r := New(slog.New(slog.NewTextHandler(os.Stdout, nil)))
	r.Handle("GET", "/test", handler)

	resp, _ := r.Route(ctx, events.APIGatewayV2HTTPRequest{
		RawPath: "/test",
		RequestContext: events.APIGatewayV2HTTPRequestContext{
			HTTP: events.APIGatewayV2HTTPRequestContextHTTPDescription{
				Method: "GET",
			},
		},
	})

	if !called {
		t.Error("handler not called")
	}
	if resp.StatusCode != 200 {
		t.Errorf("expected 200, got %d", resp.StatusCode)
	}
}

func TestRouter_NotFound(t *testing.T) {
	ctx := setupTest()
	r := New(slog.New(slog.NewTextHandler(os.Stdout, nil)))
	r.Handle("GET", "/test", func(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
		return events.APIGatewayV2HTTPResponse{StatusCode: 200}, nil
	})

	resp, _ := r.Route(ctx, events.APIGatewayV2HTTPRequest{
		RawPath: "/unknown",
		RequestContext: events.APIGatewayV2HTTPRequestContext{
			HTTP: events.APIGatewayV2HTTPRequestContextHTTPDescription{
				Method: "GET",
			},
		},
	})

	if resp.StatusCode != 404 {
		t.Errorf("expected 404, got %d", resp.StatusCode)
	}
}

func TestRouter_MethodNotAllowed(t *testing.T) {
	ctx := setupTest()
	r := New(slog.New(slog.NewTextHandler(os.Stdout, nil)))
	r.Handle("GET", "/test", func(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
		return events.APIGatewayV2HTTPResponse{StatusCode: 200}, nil
	})

	resp, _ := r.Route(ctx, events.APIGatewayV2HTTPRequest{
		RawPath: "/test",
		RequestContext: events.APIGatewayV2HTTPRequestContext{
			HTTP: events.APIGatewayV2HTTPRequestContextHTTPDescription{
				Method: "POST",
			},
		},
	})

	if resp.StatusCode != 404 {
		t.Errorf("expected 404, got %d", resp.StatusCode)
	}
}
