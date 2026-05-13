# Centralised Model Storage — `/opt/nesi/models`

Large models are stored centrally at `/opt/nesi/models` to avoid users duplicating large files across home and project directories.

## Directory Layout

```tree
/opt/nesi/models/
├── blobs/                          # actual models go here
│   └── sha256-<hash>
│
├── ollama/                         # Ollama layout
│   ├── blobs -> ../blobs/
│   └── manifests/
│       └── registry.ollama.ai/library/<model>/<size>
│
├── huggingface/                    # HuggingFace Hub layout
│   └── models--<org>--<model>/
│       └── snapshots/<hash>/
│           └── *.safetensors -> ../../../../blobs/sha256-<hash>
│
└── gguf/                           # Flat for llama.cpp and direct access
    └── <model>/
        └── <model-size>.gguf -> ../../blobs/sha256-<hash>
```

All tool-specific paths are symlinks back to `blobs/`. **No model weights are stored more than once** (per format — GGUF and safetensors are distinct files representing the same weights and cannot be shared).

## Using Models

Point your tool at the appropriate subtree via environment variable or an environment module:

| Tool | Variable | Value |
|------|----------|-------|
| Ollama | `OLLAMA_MODELS` | `/opt/nesi/models/ollama` |
| HuggingFace / vLLM | `HF_HUB_CACHE` | `/opt/nesi/models/huggingface` |
| llama.cpp / direct | — | `/opt/nesi/models/gguf/<org>/<file>.gguf` |

OLLAMA_MODELS should be set in the module.

## Adding a New Model

As `nesi-apps-admin` pull a model

```sh
module load ollama
ollama pull <model>
```

or

(provided you have huggingface installed)

```bash
HF_HUB_CACHE=/opt/nesi/models/huggingface huggingface-cli download meta-llama/Llama-3.2-3B-Instruct
```

Then run `sync.sh` to add symlinks automatically.

```bash
./sync.sh
```

DO NOT DOWNLOAD MODELS TAGGED WITH 'latest'. Download the actual tag!!!
