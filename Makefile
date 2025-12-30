.PHONY: all build clean test_details test fmt

all: build

build:
	v -W -Wimpure-v -prod .

debug:
	v -d debug .

test:
	v -gc none test vamk_tests/*_test.v

test_details:
	v -stats test vamk_tests/*_test.v

fmt:
	v fmt -w vamk_tests/ vamk/ vamk_main.v

clean:
	rm -f vamake
