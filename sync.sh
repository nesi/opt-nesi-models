#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

[[ "$(whoami)" == "nesi-apps-admin" ]] || { echo "Error: must be run as nesi-apps-admin" >&2; exit 1; }

MODELS_ROOT=/opt/nesi/models
MANIFEST_BASE="$MODELS_ROOT/ollama/manifests/registry.ollama.ai/library"

setup() {
    chmod 755 "$MODELS_ROOT"/*/
    [[ -L "$MODELS_ROOT/ollama/blobs" ]] || ln -sf ../blobs "$MODELS_ROOT/ollama/blobs"
    find "$MODELS_ROOT" -not -user nesi-apps-admin -not -type l 2>/dev/null \
        | while read -r f; do echo "WARNING: '$f' not owned by nesi-apps-admin" >&2; done
}

sync_ollama() {
    for manifest in "$MANIFEST_BASE"/*/*; do
        [[ -f "$manifest" ]] || continue
        tag=$(basename "$manifest")
        model=$(basename "$(dirname "$manifest")")
        hash=$(jq -r '.layers[] | select(.mediaType=="application/vnd.ollama.image.model") | .digest | ltrimstr("sha256:")' "$manifest" 2>/dev/null) || continue
        [[ -z "$hash" || ! -f "$MODELS_ROOT/blobs/sha256-$hash" ]] && continue
        find "$MODELS_ROOT/gguf" -type l 2>/dev/null | xargs -r readlink | grep -qF "sha256-$hash" && continue
        if [[ "$tag" == "latest" ]]; then
            echo "NAUGHTY: $model:latest isn't versioned! Pull a versioned release instead." >&2
            continue
        fi
        mkdir -p "$MODELS_ROOT/gguf/$model"
        ln -sf "$MODELS_ROOT/blobs/sha256-$hash" "$MODELS_ROOT/gguf/$model/$model-$tag.gguf"
        echo "$model:$tag -> gguf/$model/$model-$tag.gguf"
    done
}

sync_huggingface() {
    for f in "$MODELS_ROOT/huggingface/models--"*/snapshots/*/*.safetensors \
             "$MODELS_ROOT/huggingface/models--"*/snapshots/*/*.bin; do
        [[ -L "$f" ]] && continue
        hash=$(sha256sum "$f" | cut -d' ' -f1)
        mv "$f" "$MODELS_ROOT/blobs/sha256-$hash"
        chmod 644 "$MODELS_ROOT/blobs/sha256-$hash"
        ln -sf "$MODELS_ROOT/blobs/sha256-$hash" "$f"
        echo "$(basename "$f") -> blobs/sha256-$hash"
    done
}

setup
sync_ollama
sync_huggingface

