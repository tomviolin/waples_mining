
all: build run


build:
	docker build -t waples_mining .

run:
	docker kill waples_mining || echo ""
	docker rm waples_mining || echo ""
	docker run -d --name waples_mining --restart always -v /home/tomh/microservices/waples_mining/waples_mining_www:/var/www/html/waples_mining waples_mining
