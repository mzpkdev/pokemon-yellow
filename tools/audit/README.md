# Trainer data audit

Run the structural trainer-data checks from the repository root:

```sh
python tools/audit/trainers.py
```

To also emit a machine-readable manifest for reviews or balance reports:

```sh
python tools/audit/trainers.py --manifest trainer-manifest.json
```

The audit checks party sizes and levels, trainer class/party references in
`special_moves.asm`, party-slot and move-slot bounds, duplicate records, and
duplicate slot overrides. It does not modify trainer data.
