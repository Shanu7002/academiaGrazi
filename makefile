.DEFAULT_GOAL := setup
.PHONY: setup run

setup:
	@echo "==> Configuring git hooks..."
	git config core.hooksPath .githooks

# Cloud name e preset unsigned não são segredos; podem ser sobrescritos:
# make run CLOUDINARY_CLOUD_NAME=xxx CLOUDINARY_UPLOAD_PRESET=yyy
CLOUDINARY_CLOUD_NAME ?= byysbeud
CLOUDINARY_UPLOAD_PRESET ?= academia_avatars

run:
	flutter run \
		--dart-define=CLOUDINARY_CLOUD_NAME=$(CLOUDINARY_CLOUD_NAME) \
		--dart-define=CLOUDINARY_UPLOAD_PRESET=$(CLOUDINARY_UPLOAD_PRESET)
