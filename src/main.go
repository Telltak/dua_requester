package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"go.opentelemetry.io/contrib/bridges/otelslog"
	"go.opentelemetry.io/contrib/instrumentation/github.com/aws/aws-lambda-go/otellambda"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploghttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/log/global"
	"go.opentelemetry.io/otel/sdk/log"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"go.opentelemetry.io/otel/trace"
)

var logger *slog.Logger
var tp *sdktrace.TracerProvider
var lp *log.LoggerProvider

func handler(ctx context.Context) (string, error) {
	t := trace.SpanFromContext(ctx)

	trace_attrs := slog.Group("otel",
		slog.String("trace_id", t.SpanContext().TraceID().String()),
		slog.String("span_id", t.SpanContext().SpanID().String()),
	)

	logger.InfoContext(ctx, "processing lambda request",
		slog.String("status", "started"),
		slog.Int("count", 42),
		trace_attrs,
	)

	logger.InfoContext(ctx, "lambda execution complete",
		slog.String("result", "success"),
		trace_attrs,
	)

	return "Hello from Lambda", nil
}

func main() {
	ctx := context.Background()
	tp = initTracer(ctx)
	lp = initLogger(ctx)

	lambda.Start(otellambda.InstrumentHandler(handler))
}

func initTracer(ctx context.Context) *sdktrace.TracerProvider {
	exporter, err := otlptracehttp.New(ctx,
		otlptracehttp.WithEndpoint(os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")),
		otlptracehttp.WithHeaders(map[string]string{
			"x-honeycomb-team":    os.Getenv("HONEYCOMB_API_KEY"),
			"x-honeycomb-dataset": os.Getenv("HONEYCOMB_DATASET_NAME"),
		}),
	)
	if err != nil {
		panic(err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithSpanProcessor(sdktrace.NewSimpleSpanProcessor(exporter)),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String(os.Getenv("OTEL_SERVICE_NAME")),
		)),
	)
	otel.SetTracerProvider(tp)
	return tp
}

func initLogger(ctx context.Context) *log.LoggerProvider {
	exporter, err := otlploghttp.New(ctx,
		// otlploghttp.WithEndpoint("https://"+os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")),
		otlploghttp.WithHeaders(map[string]string{
			"x-honeycomb-team":    os.Getenv("HONEYCOMB_API_KEY"),
			"x-honeycomb-dataset": os.Getenv("HONEYCOMB_DATASET_NAME"),
		}),
	)
	if err != nil {
		panic(err)
	}

	lp := log.NewLoggerProvider(
		log.WithProcessor(log.NewSimpleProcessor(exporter)),
		log.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String(os.Getenv("OTEL_SERVICE_NAME")),
		)),
	)

	global.SetLoggerProvider(lp)

	logger = otelslog.NewLogger(
		os.Getenv("OTEL_SERVICE_NAME"),
		otelslog.WithLoggerProvider(lp),
	)
	return lp
}
