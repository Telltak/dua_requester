package main

import (
	"context"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"go.opentelemetry.io/contrib/instrumentation/github.com/aws/aws-lambda-go/otellambda"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
)

func handler(ctx context.Context) (string, error) {
	return "Hello from Lambda", nil
}

func main() {
	ctx := context.Background()
	_ = initTracer(ctx)

	lambda.Start(otellambda.InstrumentHandler(handler))
}

func initTracer(ctx context.Context) *sdktrace.TracerProvider {
	exporter, err := otlptracehttp.New(ctx,
		otlptracehttp.WithEndpoint(os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")),
		otlptracehttp.WithHeaders(map[string]string{
			"x-honeycomb-team": os.Getenv("HONEYCOMB_API_KEY"),
		}),
	)
	if err != nil {
		panic(err)
	}

	processor := sdktrace.NewSimpleSpanProcessor(exporter)

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithSpanProcessor(processor),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String(os.Getenv("OTEL_SERVICE_NAME")),
		)),
	)
	otel.SetTracerProvider(tp)
	return tp
}
