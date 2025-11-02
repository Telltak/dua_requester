package otel

import (
	"context"
	"log/slog"
	"os"

	"go.opentelemetry.io/contrib/bridges/otelslog"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploghttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/log/global"
	"go.opentelemetry.io/otel/sdk/log"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
)

type Config struct {
	Logger *slog.Logger
}

func New(ctx context.Context) (*Config, error) {
	tp, err := initTracer(ctx)
	if err != nil {
		return nil, err
	}
	otel.SetTracerProvider(tp)

	lp, err := initLogger(ctx)
	if err != nil {
		return nil, err
	}
	global.SetLoggerProvider(lp)

	logger := otelslog.NewLogger(
		os.Getenv("OTEL_SERVICE_NAME"),
		otelslog.WithLoggerProvider(lp),
	)

	return &Config{Logger: logger}, nil
}

func initTracer(ctx context.Context) (*sdktrace.TracerProvider, error) {
	exporter, err := otlptracehttp.New(ctx,
		otlptracehttp.WithEndpoint(os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")),
		otlptracehttp.WithHeaders(map[string]string{
			"x-honeycomb-team":    os.Getenv("HONEYCOMB_API_KEY"),
			"x-honeycomb-dataset": os.Getenv("HONEYCOMB_DATASET_NAME"),
		}),
	)
	if err != nil {
		return nil, err
	}

	return sdktrace.NewTracerProvider(
		sdktrace.WithSpanProcessor(sdktrace.NewSimpleSpanProcessor(exporter)),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String(os.Getenv("OTEL_SERVICE_NAME")),
		)),
	), nil
}

func initLogger(ctx context.Context) (*log.LoggerProvider, error) {
	exporter, err := otlploghttp.New(ctx,
		otlploghttp.WithHeaders(map[string]string{
			"x-honeycomb-team":    os.Getenv("HONEYCOMB_API_KEY"),
			"x-honeycomb-dataset": os.Getenv("HONEYCOMB_DATASET_NAME"),
		}),
	)
	if err != nil {
		return nil, err
	}

	return log.NewLoggerProvider(
		log.WithProcessor(log.NewSimpleProcessor(exporter)),
		log.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String(os.Getenv("OTEL_SERVICE_NAME")),
		)),
	), nil
}
