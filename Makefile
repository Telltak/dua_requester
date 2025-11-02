test:
	cd src && go test ./...
build:
	cd src && GOOS=linux GOARCH=amd64 go build -o ../bootstrap main.go
	zip lambda.zip bootstrap

clean:
	rm -f bootstrap lambda.zip

init:
	cd infrastructure && tfswitch && AWS_PROFILE=personal terraform init

plan:
	@test -n "$(HONEYCOMB_API_KEY)" || (echo "HONEYCOMB_API_KEY is required" && exit 1)
	cd infrastructure && AWS_PROFILE=personal terraform plan -var="honeycomb_api_key=$(HONEYCOMB_API_KEY)"

apply:
	@test -n "$(HONEYCOMB_API_KEY)" || (echo "HONEYCOMB_API_KEY is required" && exit 1)
	cd infrastructure && AWS_PROFILE=personal terraform apply -auto-approve -var="honeycomb_api_key=$(HONEYCOMB_API_KEY)"
