install:
	magic install

test:
	magic run mojo run test.mojo

format:
	magic run mojo format morrow test.mojo

build:
	magic run mojo package morrow -o morrow.mojopkg