install:
	mojo --version

test:
	mojo run test.mojo

format:
	mojo format morrow test.mojo

build:
	mojo package morrow -o morrow.mojopkg
