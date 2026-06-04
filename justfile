# pi
# https://just.systems/man/en/

set dotenv-load

image_name := "pi"
BASE_VARIANT := "shell-docker"
PI_VERSION := "latest"

# Default: show available recipes
default:
    @just --list

# Build the docker image
build base_variant=BASE_VARIANT pi_version=PI_VERSION:
    docker build \
        --build-arg BASE_VARIANT={{base_variant}} \
        --build-arg PI_VERSION={{pi_version}} \
        -t {{image_name}} \
        .

# Build the slim (non-docker) variant
build-slim pi_version=PI_VERSION:
    @just build shell {{pi_version}}

# Export image to tar
save:
    docker save {{image_name}} -o {{image_name}}.tar

# Load image into sbx runtime from tar
load:
    sbx template load {{image_name}}.tar

# Build + save + load into sbx
deploy base_variant=BASE_VARIANT pi_version=PI_VERSION:
    @just build {{base_variant}} {{pi_version}}
    @just save
    @just load

# Run sandbox with the loaded template
run:
    sbx run --template {{image_name}} shell

# --- Kit shortcuts ---

# base pre-baked image
kit-run-base:
    sbx run --kit ./sbx-kits/pi-base/ pi

# base kit + extras mixin
kit-run-base-full:
    sbx run --kit ./sbx-kits/pi-base/ --kit ./sbx-kits/pi-extras/ pi

# Generic kit + extras mixin (legacy)
kit-run-legacy:
    sbx run --kit ./sbx-kits/pi pi

# Validate all kits
kit-validate:
    sbx kit validate ./sbx-kits/pi/ # legacy
    sbx kit validate ./sbx-kits/pi-base/
    sbx kit validate ./sbx-kits/pi-extras/

# Inspect all kits
kit-inspect:
    sbx kit inspect ./sbx-kits/pi/ # legacy
    sbx kit inspect ./sbx-kits/pi-base/
    sbx kit inspect ./sbx-kits/pi-extras/

# Full cycle: build, load, run
test base_variant=BASE_VARIANT pi_version=PI_VERSION:
    @just deploy {{base_variant}} {{pi_version}}
    @just run

# Remove the exported tar file
clean:
    rm -f *.tar

# Push to GHCR
push registry="ghcr.io/shaftoe":
    docker tag {{image_name}} {{registry}}/{{image_name}}:latest
    docker push {{registry}}/{{image_name}}:latest

# Smoke test
smoke:
    ./test/smoke-test.sh {{image_name}}
